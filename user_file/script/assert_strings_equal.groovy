// JMeter built-ins: args[], AssertionResult

def actual = args[0]
def expected = args[1]

if (actual != expected) {
    AssertionResult.setFailureMessage('Expect: ' + expected + ' , found: ' + actual)
    AssertionResult.setFailure(true)
}
