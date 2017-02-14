// JMeter提供的变量：
// ctx, vars, props, sampler, log, Label, Filename, Parameters, args[], OUT
// SampleResult/prev（前置处理器除外）, AssertionResult（仅限断言）

import org.apache.commons.io.FileUtils;

File file = new File(args[0]);
String lineContent = args[1];

try {
  FileUtils.write(file, lineContent + System.lineSeparator(), "UTF-8", true);  // 传true后，不存在的文件会创建，存在的会追加
} catch (IOException ex) {
  throw new RuntimeException("[ERROR] Can not write to file: " + file.getAbsolutePath(), ex);
}
