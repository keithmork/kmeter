// JMeter提供的变量：
// ctx, vars, props, sampler, log, Label, Filename, Parameters, args[], OUT
// SampleResult/prev（前置处理器除外）, AssertionResult（仅限断言）

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.LineIterator;

File sourceFile = new File(args[0]);
File targetFile = new File(args[1]);
File tempFile = new File(sourceFile.getAbsolutePath() + ".tmp");
// 从第几行开始，最小为1
int startLine = Integer.parseInt(args[2]);
// 要移动几行
int moveLineCount = Integer.parseInt(args[3]);

LineIterator it = FileUtils.lineIterator(sourceFile, "UTF-8");
try {
  int lineNum = 1;
  while (it.hasNext()) {
    Boolean isInRange = (lineNum >= startLine) && (lineNum < startLine + moveLineCount);
    if (isInRange) {
      FileUtils.write(targetFile, it.nextLine() + System.lineSeparator(), "UTF-8", true);
    } else {
      FileUtils.write(tempFile, it.nextLine() + System.lineSeparator(), "UTF-8", true);
    }

    lineNum++;
  }
} catch (IOException ioEx) {
  throw new RuntimeException("[ERROR] Can not read from file: " + sourceFile.getAbsolutePath(), ioEx);
} finally {
  LineIterator.closeQuietly(it);
}

// 删源文件
if (!sourceFile.delete()) {
  throw new RuntimeException("[ERROR] Can not delete file: " + sourceFile.getAbsolutePath());
}
// 临时文件改名
if (!tempFile.renameTo(sourceFile)) {
  throw new RuntimeException("[ERROR] Can not rename file: " + tempFile.getAbsolutePath());
}
