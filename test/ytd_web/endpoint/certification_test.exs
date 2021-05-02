defmodule YTDWeb.Endpoint.CertificationTest do
  use ExUnit.Case, async: false
  import SiteEncrypt.Phoenix.Test

  test "certification is set up for [www.]ytd.kerryb.org" do
    clean_restart(YTDWeb.Endpoint)
    cert = get_cert(YTDWeb.Endpoint)
    assert cert.domains == ~w/ytd.kerryb.org www.ytd.kerryb.org/
  end
end
