import org.apache.commons.io.FileUtils;

// JMeter提供的变量：
// ctx, vars, props, sampler, log, Label, Filename, Parameters, args[], OUT
// SampleResult/prev（前置处理器除外）, AssertionResult（仅限断言）

for (String filename : args) {
  File file = new File(filename);

  try {
    FileUtils.forceDelete(file);
  } catch (FileNotFoundException ex) {
    log.info("[INFO] " + file.getAbsolutePath() + " does not found!", ex);
  } catch (IOException ioEx) {
    throw new RuntimeException("[ERROR] " + file.getAbsolutePath() + " can not be deleted!", ioEx);
  }
}
