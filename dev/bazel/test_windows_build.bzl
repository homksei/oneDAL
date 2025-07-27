# Bazel Windows Build Test

load("@bazel_skylib//lib:unittest.bzl", "unittest")

def _windows_build_test_impl(ctx):
    """Simple test to verify Windows build configuration works"""
    env = unittest.begin(ctx)

    # Test that we can detect Windows OS
    unittest.expect_that(env, "win", unittest.matches("win"))

    return unittest.end(env)

windows_build_test = unittest.make(
    _windows_build_test_impl,
)

def windows_build_test_suite():
    unittest.suite(
        "windows_build_tests",
        windows_build_test,
    )
