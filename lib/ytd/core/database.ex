use Amnesia

defdatabase YTD.Core.Database do
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
