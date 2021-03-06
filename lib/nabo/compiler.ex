defmodule Nabo.Compiler do
  @moduledoc false

  @default_pattern ~r/[\s\r\n]---[\s\r\n]/s

  alias Nabo.{
    Parser,
    Post
  }

  def compile(data, options) do
    {front_parser, front_parser_opts} =
      Keyword.get(options, :front_parser, {Parser.Front, []})

    {excerpt_parser, excerpt_parser_opts} =
      Keyword.get(options, :excerpt_parser, {Parser.Markdown, []})

    {body_parser, body_parser_opts} =
      Keyword.get(options, :body_parser, {Parser.Markdown, []})

    split_pattern =
      Keyword.get(options, :split_pattern, @default_pattern)

    case split_parts(data, split_pattern) do
      {:ok, {front, excerpt, body}} ->
        with {:ok, metadata} <- front_parser.parse(front, front_parser_opts),
             {:ok, parsed_excerpt} <- excerpt_parser.parse(excerpt, excerpt_parser_opts),
             {:ok, parsed_body} <- body_parser.parse(body, body_parser_opts) do
          post = Post.new(metadata, excerpt, parsed_excerpt, body, parsed_body)
          {:ok, post.slug, post}
        else
          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp split_parts(data, pattern) do
    parts =
      data
      |> String.trim_leading()
      |> String.split(pattern, parts: 3)

    case parts do
      [front, body] ->
        {:ok, {front, "", body}}

      [front, excerpt, body] ->
        {:ok, {front, excerpt, body}}

      _other ->
        {:error, "bad post format"}
    end
  end
end
