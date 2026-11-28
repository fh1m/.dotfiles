"""Keep disposable repositories independent of host-wide Git event consumers."""
import pytest


@pytest.fixture(scope="session", autouse=True)
def isolate_synthetic_git_events():
    # A global Trace2 consumer may write attribution notes after Git exits,
    # racing TemporaryDirectory cleanup. Isolate only this test process and
    # its children; normal development attribution remains enabled.
    with pytest.MonkeyPatch.context() as environment:
        environment.setenv("GIT_TRACE2_EVENT", "0")
        yield
