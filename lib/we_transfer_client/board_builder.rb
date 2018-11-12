module WeTransfer
  class BoardBuilder
    attr_reader :items, :files, :links

    def initialize
      @files = []
      @links = []
    end

    def items
      (@files + @links).flatten
    end

    def add_file(name:, size:)
      @files << FutureFile.new(name: name, size: size)
    end

    def add_file_at(path:)
      add_file(name: File.basename(path), size: File.size(path))
    end

    def add_web_url(url:, title: url)
      @links << FutureLink.new(url: url, title: title)
    end

    def select_file_on_name(name: )
      file = files.select{|f| f.name == name}.first
      return file if file #Todo: this could be done different
      raise WeTransfer::TransferIOError, 'File not found'
    end
  end
end