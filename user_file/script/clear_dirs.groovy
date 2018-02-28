import org.apache.commons.io.FileUtils

// JMeter built-ins: args[]

for (def dirname : args) {
    def dir = new File(dirname)

    try {
        FileUtils.cleanDirectory(dir);
    } catch (IllegalArgumentException ignored) {  // make dir if not exist
        FileUtils.forceMkdir(dir)
    } catch (IOException ioEx) {
        throw new RuntimeException('[ERROR] Cannot clear directory: ' + dir.getAbsolutePath(), ioEx)
    }
}
