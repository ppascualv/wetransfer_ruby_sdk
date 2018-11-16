module WeTransfer
  class Board
    attr_reader :remote_board

    def initialize(client:, name:, description: nil)
      @client = client
      @remote_board = create_remote_board(name: name, description: description)
      @builder = WeTransfer::BoardBuilder.new(client: @client)
    end

    def add_items
      yield(@builder)
      add_items_to_remote_board(future_items: @builder.items)
    rescue LocalJumpError
      raise ArgumentError, 'No items where added to the board'
    end

    def upload_file!(io:, name: File.basename(io.to_path))
      local_file = @builder.select_file_on_name(name: name)
      local_file.upload_file(io: io)
    end

    def complete_file!(name:)
      local_file = @builder.select_file_on_name(name: name)
      local_file.complete_file
    end

    private

    def create_remote_board(name:, description:, future_board_class: FutureBoard)
      future_board = future_board_class.new(name: name, description: description)
      @client.authorize_if_no_bearer_token!
      response = @client.faraday.post(
        '/v2/boards',
        JSON.pretty_generate(future_board.to_initial_request_params),
        @client.auth_headers.merge('Content-Type' => 'application/json')
      )
      @client.ensure_ok_status!(response)
      WeTransfer::RemoteBoard.new(JSON.parse(response.body, symbolize_names: true))
    end

    def add_items_to_remote_board(future_items:)
      future_items.group_by(&:class).each do |_group, grouped_items|
        grouped_items.each do |item|
          item.add_to_board(remote_board: @remote_board)
        end
      end
      @remote_board
    end
  end
end