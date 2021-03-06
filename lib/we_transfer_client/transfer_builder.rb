class TransferBuilder
  attr_reader :files
  class TransferIOError < StandardError; end

  def initialize
    @files = []
  end

  def add_file(name:, io:)
    ensure_io_compliant!(io)
    @files << FutureFile.new(name: name, io: io)
  end

  def add_file_at(path:)
    add_file(name: File.basename(path), io: File.open(path, 'rb'))
  end

  def ensure_io_compliant!(io)
    io.seek(0)
    io.read(1) # Will cause things like Errno::EACCESS to happen early, before the upload begins
    io.seek(0) # Also rewinds the IO for later uploading action
    size = io.size # Will cause a NoMethodError
    raise TransferIOError, 'The IO object given to add_file has a size of 0' if size <= 0
  rescue NoMethodError
    raise TransferIOError, "The IO object given to add_file must respond to seek(), read() and size(), but #{io.inspect} did not"
  end
end
