use Amnesia

defdatabase YTD.Database do
  deftable(Athlete,
           [:id, :token, :run_target, :ride_target],
           type: :set, index: [:token]) do
    @type t :: %Athlete{id: integer, token: String.t, run_target: integer}
  end

  def setup do
    :stopped = Amnesia.stop
    :ok = Amnesia.Schema.create
    :ok = Amnesia.start
    :ok = create!(disk: [node()])
  end

  def migrate do
    case Athlete.info :attributes do
      [:id, :token, :run_target, :ride_target] ->
        :ok
      [:id, :token, :target] ->
        Amnesia.Table.transform(Athlete,
                                [:id, :token, :run_target, :ride_target],
                                fn {Athlete, id, token, target} ->
                                  {Athlete, id, token, target, nil}
                                end)
      other ->
        {:error, other}
    end
  end
end
