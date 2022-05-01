import os
import time

from contextlib import contextmanager
import logging

from alembic.migration import MigrationContext  # pylint: disable=import-error
from alembic.script import ScriptDirectory
import sqlalchemy

from mlflow.exceptions import MlflowException
from mlflow.store.tracking.dbmodels.initial_models import Base as InitialBase
from mlflow.protos.databricks_pb2 import BAD_REQUEST, INTERNAL_ERROR
from mlflow.store.db.db_types import SQLITE

_logger = logging.getLogger(__name__)

MLFLOW_SQLALCHEMYSTORE_POOL_SIZE = "MLFLOW_SQLALCHEMYSTORE_POOL_SIZE"
MLFLOW_SQLALCHEMYSTORE_MAX_OVERFLOW = "MLFLOW_SQLALCHEMYSTORE_MAX_OVERFLOW"
MLFLOW_SQLALCHEMYSTORE_POOL_CLASS = "MLFLOW_SQLALCHEMYSTORE_POOL_CLASS"
MAX_RETRY_COUNT = 15


def _get_package_dir():
    """Returns directory containing MLflow python package."""
    current_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.normpath(os.path.join(current_dir, os.pardir, os.pardir))


def _initialize_tables(engine):
    _logger.info("Creating initial MLflow database tables...")
    InitialBase.metadata.create_all(engine)
    _upgrade_db(engine)


def _get_latest_schema_revision():
    """Get latest schema revision as a string."""
    # We aren't executing any commands against a DB, so we leave the DB URL unspecified
    config = _get_alembic_config(db_url="")
    script = ScriptDirectory.from_config(config)
    heads = script.get_heads()
    if len(heads) != 1:
        raise MlflowException(
            "Migration script directory was in unexpected state. Got %s head "
            "database versions but expected only 1. Found versions: %s" % (len(heads), heads)
        )
    return heads[0]


def _verify_schema(engine):
    head_revision = _get_latest_schema_revision()
    current_rev = _get_schema_version(engine)
    if current_rev != head_revision:
        raise MlflowException(
            "Detected out-of-date database schema (found version %s, but expected %s). "
            "Take a backup of your database, then run 'mlflow db upgrade <database_uri>' "
            "to migrate your database to the latest schema. NOTE: schema migration may "
            "result in database downtime - please consult your database's documentation for "
            "more detail." % (current_rev, head_revision)
        )


def _get_managed_session_maker(SessionMaker, db_type):
    """
    Creates a factory for producing exception-safe SQLAlchemy sessions that are made available
    using a context manager. Any session produced by this factory is automatically committed
    if no exceptions are encountered within its associated context. If an exception is
    encountered, the session is rolled back. Finally, any session produced by this factory is
    automatically closed when the session's associated context is exited.
    """

    @contextmanager
    def make_managed_session():
        """Provide a transactional scope around a series of operations."""
        session = SessionMaker()
        try:
            if db_type == SQLITE:
                session.execute("PRAGMA foreign_keys = ON;")
                session.execute("PRAGMA case_sensitive_like = true;")
            yield session
            session.commit()
        except MlflowException:
            session.rollback()
            raise
        except sqlalchemy.exc.SQLAlchemyError as e:
            session.rollback()
            raise MlflowException(message=e, error_code=BAD_REQUEST)
        except Exception as e:
            session.rollback()
            raise MlflowException(message=e, error_code=INTERNAL_ERROR)
        finally:
            session.close()

    return make_managed_session


def _get_alembic_config(db_url, alembic_dir=None):
    """
    Constructs an alembic Config object referencing the specified database and migration script
    directory.
    :param db_url Database URL, like sqlite:///<absolute-path-to-local-db-file>. See
    https://docs.sqlalchemy.org/en/13/core/engines.html#database-urls for a full list of valid
    database URLs.
    :param alembic_dir Path to migration script directory. Uses canonical migration script
    directory under mlflow/alembic if unspecified. TODO: remove this argument in MLflow 1.1, as
    it's only used to run special migrations for pre-1.0 users to remove duplicate constraint
    names.
    """
    from alembic.config import Config

    final_alembic_dir = (
        os.path.join(_get_package_dir(), "store", "db_migrations")
        if alembic_dir is None
        else alembic_dir
    )
    # Escape any '%' that appears in a db_url. This could be in a password,
    # url, or anything that is part of a potentially complex database url
    db_url = db_url.replace("%", "%%")
    config = Config(os.path.join(final_alembic_dir, "alembic.ini"))
    config.set_main_option("script_location", final_alembic_dir)
    config.set_main_option("sqlalchemy.url", db_url)
    return config


def _upgrade_db(engine):
    """
    Upgrade the schema of an MLflow tracking database to the latest supported version.
    Note that schema migrations can be slow and are not guaranteed to be transactional -
    we recommend taking a backup of your database before running migrations.
    :param url Database URL, like sqlite:///<absolute-path-to-local-db-file>. See
    https://docs.sqlalchemy.org/en/13/core/engines.html#database-urls for a full list of valid
    database URLs.
    """
    # alembic adds significant import time, so we import it lazily
    from alembic import command

    db_url = str(engine.url)
    _logger.info("Updating database tables")
    config = _get_alembic_config(db_url)
    # Initialize a shared connection to be used for the database upgrade, ensuring that
    # any connection-dependent state (e.g., the state of an in-memory database) is preserved
    # for reference by the upgrade routine. For more information, see
    # https://alembic.sqlalchemy.org/en/latest/cookbook.html#sharing-a-
    # connection-with-a-series-of-migration-commands-and-environments
    with engine.begin() as connection:
        config.attributes["connection"] = connection  # pylint: disable=E1137
        command.upgrade(config, "heads")


def _get_schema_version(engine):
    with engine.connect() as connection:
        mc = MigrationContext.configure(connection)
        return mc.get_current_revision()


def create_sqlalchemy_engine_with_retry(db_uri):
    attempts = 0
    while True:
        attempts += 1
        engine = create_sqlalchemy_engine(db_uri)
        try:
            sqlalchemy.inspect(engine)
            return engine
        except Exception as e:
            if attempts < MAX_RETRY_COUNT:
                sleep_duration = 0.1 * ((2**attempts) - 1)
                _logger.warning(
                    "SQLAlchemy engine could not be created. The following exception is caught.\n"
                    "%s\nOperation will be retried in %.1f seconds",
                    e,
                    sleep_duration,
                )
                time.sleep(sleep_duration)
                continue
            raise


def create_sqlalchemy_engine(db_uri):
    pool_size = os.environ.get(MLFLOW_SQLALCHEMYSTORE_POOL_SIZE)
    pool_max_overflow = os.environ.get(MLFLOW_SQLALCHEMYSTORE_MAX_OVERFLOW)
    pool_class = os.environ.get(MLFLOW_SQLALCHEMYSTORE_POOL_CLASS)
    pool_kwargs = {}
    # Send argument only if they have been injected.
    # Some engine does not support them (for example sqllite)
    if pool_size:
        pool_kwargs["pool_size"] = int(pool_size)
    if pool_max_overflow:
        pool_kwargs["max_overflow"] = int(pool_max_overflow)
    if pool_class:
        pool_class = getattr(sqlalchemy.pool, pool_class)
        _logger.info("Using custom pool class: %s", pool_class)
    if pool_kwargs:
        _logger.info("Create SQLAlchemy engine with pool options %s", pool_kwargs)
    return sqlalchemy.create_engine(db_uri, pool_pre_ping=True, poolclass=pool_class, **pool_kwargs)