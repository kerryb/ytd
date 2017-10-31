use Amnesia

defdatabase YTDCore.Database do
  @moduledoc """
  This module has been left behind to allow for database migration, which
  should be done thusly:

  Export the database:

      /opt/ytd/bin/ytd remote_console
      > Amnesia.dump "database.dump"

  Stop the application:

      /opt/ytd/bin/ytd stop

  Munge the dump file:

      sed -i.orig 's/YTDCore/YTD/g' /opt/ytd/database.dump

  Remove (or rename) the database files (`/opt/ytd/Mnesia*`)

  Start the application:

      /opt/ytd/bin/ytd start

  Import the database:

      /opt/ytd/bin/ytd remote_console
      > Amnesia.load "database.dump"
  """

  deftable Athlete, [:id, :token, :target], type: :set do
    @type t :: %Athlete{id: integer, token: String.t, target: integer}
  end

  def setup do
    :stopped = Amnesia.stop
    :ok = Amnesia.Schema.create
    :ok = Amnesia.start
    :ok = create!(disk: [node()])
  end
end
