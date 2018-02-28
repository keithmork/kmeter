import org.apache.commons.io.FileUtils

// JMeter built-ins：args[]

def file = new File(args[0])
def lineContent = args[1]

try {
    FileUtils.write(file, lineContent + System.lineSeparator(), 'UTF-8', true)  // append
} catch (IOException ex) {
    throw new RuntimeException('[ERROR] Error writing file: ' + file.getAbsolutePath(), ex)
}
