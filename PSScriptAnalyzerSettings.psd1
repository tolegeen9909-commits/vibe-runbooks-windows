@{
    Severity = @('Error', 'Warning')
    ExcludeRules = @(
        # The runbooks intentionally use colored, user-facing console output.
        'PSAvoidUsingWriteHost'
    )
}
