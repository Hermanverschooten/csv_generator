defmodule CsvGenerator do
  @moduledoc File.read!("README.md")

  @types [:string, :integer, :float, :date, :datetime, :time]

  defmacro __using__(_options) do
    quote do
      Module.register_attribute(__MODULE__, :columns, accumulate: true, persist: false)
      Module.register_attribute(__MODULE__, :delimiter, accumulate: false, persist: false)
      Module.register_attribute(__MODULE__, :line_ending, accumulate: false, persist: false)
      Module.register_attribute(__MODULE__, :decimal_point, accumulate: false, persist: false)
      Module.register_attribute(__MODULE__, :hardcoded, accumulate: false, persist: false)
      Module.register_attribute(__MODULE__, :no_header, accumulate: false, persist: false)
      import unquote(__MODULE__)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    compile(
      Module.get_attribute(env.module, :columns) |> Enum.reverse(),
      Module.get_attribute(env.module, :delimiter, ","),
      Module.get_attribute(env.module, :line_ending, "\n"),
      Module.get_attribute(env.module, :decimal_point, "."),
      Module.get_attribute(env.module, :no_header, false)
    )
  end

  @doc """
  Defines a column in the CSV.

  `column name, type, options`

  The column name will be used to select the value from the given input.

  The following types are currently supported:

  Type         | Elixir type             | Default format
  :----------- | :---------------------- | :------------------
  `:string`    | `String`                | n/a
  `:integer`   | `Integer`               | n/a
  `:float`     | `Float`                 | n/a
  `:date`      | `Date`                  | `"%Y-%m-%d"`
  `:time`      | `DateTime` or `Integer` | `"%H:%M"`
  `:datetime`  | `DateTime`              | `"%Y-%m-%d %H:%M:%S"`

  For `:date`, `:time`, and `:datetime`, any of the Date(Time) types that
  are compatible with `Calendar.Strftime.strftime/2` are allowed.
  `:time` also allows an `Integer` value that represents the time within a day.

  ## Options

    * `:header` - Use this instead of the name for column header.

    * `:format` - Supply a different format string, see https://hexdocs.pm/calendar/readme.html.

    * `:digits` - Supply the number of digits for a `Float`.

    * `:with`   - Specifies a function to be called on the value before processing.
                  column :value, :integer, with: &calc/1 or
                  column :value, :integer, with: fn(x) -> x * 2 end
    * `:source` - Use another field as the source for this column, this allows you to use the same column multiple times.
  """
  defmacro column(_name, type, opts \\ [])

  defmacro column(_name, type, _opts)
           when not (type in @types) do
    raise(ArgumentError, "type should be one of #{inspect(@types)} on line #{__CALLER__.line}")
  end

  defmacro column(name, type, opts) do
    # This makes it possible to pass an anonymous function to :with
    parms =
      case Keyword.get(opts, :with) do
        nil -> opts
        _ -> Keyword.update!(opts, :with, &Macro.escape/1)
      end

    quote bind_quoted: [name: name, type: type, opts: parms] do
      @columns {name, type, opts}
    end
  end

  @doc """
  Defines a column in the CSV that will always have the same hardcoded value.

  ## Example

      hardcoded :string, "name", "John"

  For `type` check out the possibilities in `column/3`.
  Make sure the `value` is of `type`.
  """

  defmacro hardcoded(type, _header, _value)
           when not (type in @types) do
    raise(ArgumentError, "type should be one of #{inspect(@types)} on line #{__CALLER__.line}")
  end

  defmacro hardcoded(_type, header, _value) when not is_binary(header) do
    raise(ArgumentError, "header should be a string on line #{__CALLER__.line}")
  end

  defmacro hardcoded(type, header, value) do
    opts = [hardcoded: value, header: header]

    quote bind_quoted: [type: type, opts: opts] do
      @columns {"hardcoded#{length(@columns)}" |> String.to_atom(), type, opts}
    end
  end

  @doc """
  Specify the character to use as column delimiter, default: ","

  ## Example

      delimiter ";"
  """
  defmacro delimiter(char) when is_binary(char) do
    quote bind_quoted: [char: char] do
      @delimiter char
    end
  end

  defmacro delimiter(_) do
    raise(ArgumentError, "delimiter expects a binary on line #{__CALLER__.line}.")
  end

  @doc """
  Specify the line ending to use, default: "\\n".

  ## Example

      line_ending "\\r\\n"
  """
  defmacro line_ending(char) when is_binary(char) do
    quote bind_quoted: [char: char] do
      @line_ending char
    end
  end

  defmacro line_ending(_) do
    raise(ArgumentError, "line_ending expects a binary on line #{__CALLER__.line}.")
  end

  @doc """
  Specify the decimal point, default: "."

  ## Example

      decimal_point ","
  """
  defmacro decimal_point(char) when is_binary(char) do
    quote bind_quoted: [char: char] do
      @decimal_point char
    end
  end

  defmacro decimal_point(_) do
    raise(ArgumentError, "decimal_point expects a binary on line #{__CALLER__.line}.")
  end

  @doc """
  Add the header to the generated CSV, default: true.

  ## Example

      header false

  """
  defmacro header(flag) when is_boolean(flag) do
    quote bind_quoted: [flag: !flag] do
      @no_header flag
    end
  end

  defmacro header(_flag) do
    raise(ArgumentError, "header takes a boolean on line #{__CALLER__.line}.")
  end

  @doc false
  def compile(columns, delimiter, line_ending, decimal_point, no_header) do
    headers = gen_header(columns, delimiter)

    columns_ast = gen_columns(columns, decimal_point)

    columns_fn =
      Enum.map(columns, fn {name, _type, opts} ->
        case Keyword.get(opts, :hardcoded) do
          nil ->
            value = Keyword.get(opts, :source, name)

            quote do
              render(unquote(name), Map.get(row, unquote(value)))
            end

          value ->
            quote bind_quoted: [name: name, value: Macro.escape(value)] do
              render(name, value)
            end
        end
      end)

    row_fn =
      quote do
        Enum.map(list, fn row ->
          unquote(columns_fn)
          |> Enum.join(unquote(delimiter))
        end)
      end

    list_fn =
      if no_header do
        row_fn
      else
        quote do
          [unquote(headers) | unquote(row_fn)]
        end
      end

    quote do
      unquote(columns_ast)

      @doc """
      Called to render the CSV output.

      ## Example

         iex> MyCSV.render(list)
         "..."
      """
      def render(list) when is_list(list) do
        unquote(list_fn) |> Enum.join(unquote(line_ending))
      end
    end
  end

  defp gen_header(columns, delimiter) do
    Enum.map(columns, fn {name, _type, opts} ->
      ~s("#{Keyword.get(opts, :header, name)}")
    end)
    |> Enum.join(delimiter)
  end

  defp gen_columns(columns, decimal_point) do
    for {name, type, opts} <- columns do
      {fname, func} =
        case Keyword.get(opts, :with) do
          nil ->
            {:render,
             quote do
               # test
             end}

          with_function ->
            {:post_render,
             quote do
               def render(unquote(name), value) do
                 post_render(unquote(name), unquote(with_function).(value))
               end
             end}
        end

      case type do
        :string ->
          quote do
            unquote(func)

            def unquote(fname)(unquote(name), value) do
              ~s("#{value}")
            end
          end

        :integer ->
          quote do
            @doc false
            unquote(func)

            @doc false
            def unquote(fname)(unquote(name), nil), do: 0

            def unquote(fname)(unquote(name), value) when is_integer(value) do
              value
            end

            def unquote(fname)(unquote(name), value) when is_binary(value) do
              value
            end

            def unquote(fname)(unquote(name), value) do
              raise "Invalid value for #{unquote(name)}: #{inspect(value)}"
            end
          end

        :float ->
          convert =
            case {Keyword.get(opts, :digits), decimal_point} do
              {nil, "."} ->
                quote do
                  v
                end

              {nil, char} ->
                quote do
                  v
                  |> to_string
                  |> String.replace(".", unquote(char))
                end

              {digits, "."} ->
                divisor = 5 / :math.pow(10, digits + 2)

                quote do
                  Float.round(v + unquote(divisor), unquote(digits))
                end

              {digits, char} ->
                divisor = 5 / :math.pow(10, digits + 2)

                quote do
                  Float.round(v + unquote(divisor), unquote(digits))
                  |> to_string
                  |> String.replace(".", unquote(char))
                end
            end

          quote do
            unquote(func)

            def unquote(fname)(unquote(name), value) do
              v =
                cond do
                  is_nil(value) ->
                    0.0

                  is_float(value) ->
                    value

                  is_binary(value) ->
                    case Float.parse(value) do
                      :error ->
                        raise "Cannort parse float value \"#{inspect(value)}\""

                      {f, _} ->
                        f
                    end

                  true ->
                    raise "Invalid float value \"#{inspect(value)}\""
                end

              unquote(convert)
            end
          end

        :date ->
          quote do
            unquote(func)

            def unquote(fname)(unquote(name), nil), do: ""

            def unquote(fname)(unquote(name), value) do
              Calendar.Strftime.strftime!(value, unquote(Keyword.get(opts, :format, "%Y-%m-%d")))
            end
          end

        :time ->
          quote do
            unquote(func)

            def unquote(fname)(unquote(name), nil), do: ""

            def unquote(fname)(unquote(name), value) when is_integer(value) do
              unquote(fname)(unquote(name), DateTime.from_unix!(value))
            end

            def unquote(fname)(unquote(name), value) do
              Calendar.Strftime.strftime!(
                value,
                unquote(Keyword.get(opts, :format, "%H:%M"))
              )
            end
          end

        :datetime ->
          quote do
            unquote(func)

            def unquote(fname)(unquote(name), nil), do: ""

            def unquote(fname)(unquote(name), value) do
              Calendar.Strftime.strftime!(
                value,
                unquote(Keyword.get(opts, :format, "%Y-%m-%d %H:%M:%S"))
              )
            end
          end
      end
    end
  end
end
