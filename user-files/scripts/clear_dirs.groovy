// JMeter提供的变量：
// ctx, vars, props, sampler, log, Label, Filename, Parameters, args[], OUT
// SampleResult/prev（前置处理器除外）, AssertionResult（仅限断言）

import org.apache.commons.io.FileUtils;

for (String dirname : args) {
  File dir = new File(dirname);

  try {
    FileUtils.cleanDirectory(dir);
  } catch (IllegalArgumentException ignored) {  // 目录不存在就新建
    FileUtils.forceMkdir(dir);
  } catch (IOException ioEx) {
    throw new RuntimeException("[ERROR] Cannot clear directory: " + dir.getAbsolutePath(), ioEx);
  }
}
