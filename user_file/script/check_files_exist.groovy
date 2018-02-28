// JMeter built-ins: args[], SampleResult

for (def filename : args) {
    def file = new File(filename);

    if (!file.exists() || !file.isFile()) {
        SampleResult.setStopTestNow(true)
        throw new RuntimeException('[ERROR] Cannot find file: ' + file.getAbsolutePath())
    }
}
