import org.apache.commons.io.FileUtils
import org.apache.commons.io.LineIterator

// JMeter built-ins: args[]

def sourceFile = new File(args[0])
def targetFile = new File(args[1])
def tempFile = new File(sourceFile.getAbsolutePath() + '.tmp')

def startLine = args[2].toInteger()  // start from 1
def moveLineCount = args[3].toInteger()

def it = FileUtils.lineIterator(sourceFile, 'UTF-8')
try {
    def lineNum = 1
    while (it.hasNext()) {
        def isInRange = (lineNum >= startLine) && (lineNum < startLine + moveLineCount)
        if (isInRange) {
            FileUtils.write(targetFile, it.nextLine() + System.lineSeparator(), 'UTF-8', true)  // append
        } else {
            FileUtils.write(tempFile, it.nextLine() + System.lineSeparator(), 'UTF-8', true)
        }

        lineNum++
    }
} catch (IOException ioEx) {
    throw new RuntimeException('[ERROR] Cannot read file: ' + sourceFile.getAbsolutePath(), ioEx)
} finally {
    LineIterator.closeQuietly(it)
}

// delete source file
if (!sourceFile.delete()) {
    throw new RuntimeException('[ERROR] Cannot delete file: ' + sourceFile.getAbsolutePath())
}
// rename temp file
if (!tempFile.renameTo(sourceFile)) {
    throw new RuntimeException('[ERROR] Cannot rename file: ' + tempFile.getAbsolutePath())
}
