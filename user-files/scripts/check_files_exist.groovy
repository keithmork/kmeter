// JMeter提供的变量：
// ctx, vars, props, sampler, log, Label, Filename, Parameters, args[], OUT
// SampleResult/prev（前置处理器除外）, AssertionResult（仅限断言）

for (String filename : args) {
  File file = new File(filename);

  if (!file.exists() || !file.isFile()) {
    SampleResult.setStopTestNow(true);
    throw new RuntimeException("[ERROR] " + file.getAbsolutePath() + " does not found or is not a file!");
  }
}
