defmodule Supabase.Storage.ObjectHandler do
  @moduledoc """
  A low-level API interface for managing objects within a Supabase bucket.

  ## Responsibilities

  - **File Management**: Create, move, copy, and get information about files in a bucket.
  - **Object Listing**: List objects based on certain criteria, like a prefix.
  - **Object Removal**: Delete specific objects or a list of objects.
  - **URL Management**: Generate signed URLs for granting temporary access to objects.
  - **Content Access**: Retrieve the content of an object or stream it.

  ## Usage Warning

  This module is meant for internal use or for developers requiring more control over object management in Supabase. In general, users should work with the higher-level Supabase.Storage API when possible, as it may offer better abstractions and safety mechanisms.

  Directly interfacing with this module bypasses any additional logic the main API might provide. Use it with caution and ensure you understand its operations.
  """

  alias Supabase.Client
  alias Supabase.Fetcher
  alias Supabase.Storage.Endpoints
  alias Supabase.Storage.Object
  alias Supabase.Storage.ObjectOptions, as: Opts
  alias Supabase.Storage.SearchOptions, as: Search

  @type bucket_name :: String.t()
  @type object_path :: Path.t()
  @type file_path :: Path.t()
  @type opts :: Opts.t()
  @type search_opts :: Search.t()
  @type wildcard :: String.t()
  @type prefix :: String.t()

  @spec create_file(Clien.t(), bucket_name, object_path, file_path, opts) ::
          {:ok, Object.t()} | {:error, String.t()}
  def create_file(%Client{} = client, bucket, object_path, file_path, %Opts{} = opts) do
    uri = Endpoints.file_upload(bucket, object_path)
    url = Client.retrieve_storage_url(client, uri)

    headers =
      Fetcher.apply_client_headers(client, nil, [
        {"cache-control", "max-age=#{opts.cache_control}"},
        {"content-type", opts.content_type},
        {"x-upsert", to_string(opts.upsert)}
      ])

    Fetcher.upload(:post, url, file_path, headers)
  rescue
    File.Error -> {:error, :file_not_found}
  end

  @spec move(Client.t(), bucket_name, object_path, object_path) ::
          {:ok, :moved} | {:error, String.t()}
  def move(%Client{} = client, bucket_id, path, to) do
    url = Client.retrieve_storage_url(client, Endpoints.file_move())
    headers = Fetcher.apply_client_headers(client)
    body = %{bucket_id: bucket_id, source_key: path, destination_key: to}

    url
    |> Fetcher.post(body, headers)
    |> case do
      {:ok, _} -> {:ok, :moved}
      {:error, msg} -> {:error, msg}
    end
  end

  @spec copy(Client.t, bucket_name, object_path, object_path) ::
          {:ok, :copied} | {:error, String.t()}
  def copy(%Client{} = client, bucket_id, path, to) do
    url = Client.retrieve_storage_url(client, Endpoints.file_copy())
    headers = Fetcher.apply_client_headers(client)
    body = %{bucket_id: bucket_id, source_key: path, destination_key: to}

    url
    |> Fetcher.post(body, headers)
    |> case do
      {:ok, _} -> {:ok, :copied}
      {:error, msg} -> {:error, msg}
    end
  end

  @spec get_info(Client.t(), bucket_name, wildcard) ::
          {:ok, Object.t()} | {:error, String.t()}
  def get_info(%Client{} = client, bucket_name, wildcard) do
    uri = Endpoints.file_info(bucket_name, wildcard)
    url = Client.retrieve_storage_url(client, uri)
    headers = Fetcher.apply_client_headers(client)

    url
    |> Fetcher.get(nil, headers, resolve_json: true)
    |> case do
      {:ok, data} -> {:ok, Object.parse!(data)}
      {:error, msg} -> {:error, msg}
    end
  end

  @spec list(Client.t(), bucket_name, prefix, search_opts) ::
          {:ok, [Object.t()]} | {:error, String.t()}
  def list(%Client{} = client, bucket_name, prefix, %Search{} = opts) do
    uri = Endpoints.file_list(bucket_name)
    url = Client.retrieve_storage_url(client, uri)
    headers = Fetcher.apply_client_headers(client)
    body = Map.merge(%{prefix: prefix}, Map.from_struct(opts))

    url
    |> Fetcher.post(body, headers)
    |> case do
      {:ok, data} -> {:ok, Enum.map(data, &Object.parse!/1)}
      {:error, msg} -> {:error, msg}
    end
  end

  @spec remove(Client.t(), bucket_name, object_path) ::
          {:ok, :deleted} | {:error, String.t()}
  def remove(%Client{} = client, bucket_name, path) do
    remove_list(client, bucket_name, [path])
  end

  @spec remove_list(Client.t, bucket_name, list(object_path)) ::
          {:ok, :deleted} | {:error, String.t()}
  def remove_list(%Client{} = client, bucket_name, paths) do
    uri = Endpoints.file_remove(bucket_name)
    url = Client.retrieve_storage_url(client, uri)
    headers = Fetcher.apply_client_headers(client)

    url
    |> Fetcher.delete(%{prefixes: paths}, headers)
    |> case do
      {:ok, _} -> {:ok, :deleted}
      {:error, msg} -> {:error, msg}
    end
  end

  @spec create_signed_url(Client.t, bucket_name, object_path, integer) ::
          {:ok, String.t()} | {:error, String.t()}
  def create_signed_url(%Client{} = client, bucket_name, path, expires_in) do
    uri = Endpoints.file_signed_url(bucket_name, path)
    url = Client.retrieve_storage_url(client, uri)
    headers = Fetcher.apply_client_headers(client)

    url
    |> Fetcher.post(%{expiresIn: expires_in}, headers)
    |> case do
      {:ok, data} -> {:ok, data["signedURL"]}
      {:error, msg} -> {:error, msg}
    end
  end

  @spec get(Client.t, bucket_name, object_path) ::
      {:ok, binary} | {:error, String.t()}
  def get(%Client{} = client, bucket_name, wildcard) do
    uri = Endpoints.file_download(bucket_name, wildcard)
    url = Client.retrieve_storage_url(client, uri)
    headers = Fetcher.apply_client_headers(client)

    url
    |> Fetcher.get(nil, headers, resolve_json: true)
    |> case do
      {:ok, data} -> {:ok, data}
      {:error, msg} -> {:error, msg}
    end
  end

  @spec get_lazy(Client.t, bucket_name, wildcard) ::
          {:ok, Stream.t()} | {:error, atom}
  def get_lazy(%Client{} = client, bucket_name, wildcard) do
    uri = Endpoints.file_download(bucket_name, wildcard)
    url = Client.retrieve_storage_url(client, uri)
    headers = Fetcher.apply_client_headers(client)
    Fetcher.stream(url, headers)
  end
end
