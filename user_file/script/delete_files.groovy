import org.apache.commons.io.FileUtils

// JMeter built-ins: args[], log

for (def filename : args) {
    def file = new File(filename)

    try {
        FileUtils.forceDelete(file)
    } catch (FileNotFoundException ex) {
        log.info('[INFO] Cannot find file: ' + file.getAbsolutePath(), ex)
    } catch (IOException ioEx) {
        throw new RuntimeException('[ERROR] Cannot delete file: ' + file.getAbsolutePath(), ioEx)
    }
}
