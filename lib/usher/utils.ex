defmodule Usher.Utils do
  @moduledoc """
  Utils for Usher.
  """
  alias Framework.Utils

  def format_date(nil), do: "--"

  def format_date(date) do
    Calendar.strftime(date, "%d/%m/%Y")
  end

  def format_datetime(nil), do: "--"

  def format_datetime(datetime) do
    Calendar.strftime(datetime, "%d/%m/%Y %H:%M")
  end
end
