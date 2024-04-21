defmodule Supabase.Storage.BucketHandler do
  @moduledoc """
  Provides low-level API functions for managing Supabase Storage buckets.

  The `BucketHandler` module offers a collection of functions that directly interact with the Supabase Storage API for managing buckets. This module works closely with the `Supabase.Fetcher` for sending HTTP requests.

  ## Features

  - **Bucket Listing**: Fetch a list of all the buckets available in the storage.
  - **Bucket Retrieval**: Retrieve detailed information about a specific bucket.
  - **Bucket Creation**: Create a new bucket with specified attributes.
  - **Bucket Update**: Modify the attributes of an existing bucket.
  - **Bucket Emptying**: Empty the contents of a bucket without deleting the bucket itself.
  - **Bucket Deletion**: Permanently remove a bucket and its contents.

  ## Caution

  This module provides a low-level interface to Supabase Storage buckets and is designed for internal use by the `Supabase.Storage` module. Direct use is discouraged unless you need to perform custom or unsupported actions that are not available through the higher-level API. Incorrect use can lead to unexpected results or data loss.

  ## Implementation Details

  All functions within the module expect a base URL, API key, and access token as their initial arguments, followed by any additional arguments required for the specific operation. Responses are usually in the form of `{:ok, result}` or `{:error, message}` tuples.
  """

  alias Supabase.Client
  alias Supabase.Fetcher
  alias Supabase.Storage.Bucket
  alias Supabase.Storage.Endpoints

  @type bucket_id :: String.t()
  @type bucket_name :: String.t()
  @type create_attrs :: %{
          id: String.t(),
          name: String.t(),
          file_size_limit: integer | nil,
          allowed_mime_types: list(String.t()) | nil,
          public: boolean
        }
  @type update_attrs :: %{
          public: boolean | nil,
          file_size_limit: integer | nil,
          allowed_mime_types: list(String.t()) | nil
        }

  @spec list(Client.t()) :: {:ok, [Bucket.t()]} | {:error, String.t()}
  def list(%Client{} = client) do
    headers = Fetcher.apply_client_headers(client)
    url = Client.retrieve_storage_url(client, Endpoints.bucket_path())

    url
    |> Fetcher.get(nil, headers, resolve_json: true)
    |> case do
      {:ok, body} -> {:ok, Enum.map(body, &Bucket.parse!/1)}
      {:error, msg} -> {:error, msg}
    end
  end

  @spec retrieve_info(Client.t, String.t) :: {:ok, Bucket.t()} | {:error, String.t()}
  def retrieve_info(%Client{} = client, bucket_id) do
    uri = Endpoints.bucket_path_with_id(bucket_id)
    url = Client.retrieve_storage_url(client, uri)
    headers = Fetcher.apply_client_headers(client)

    url
    |> Fetcher.get(nil, headers, resolve_json: true)
    |> case do
      {:ok, body} -> {:ok, Bucket.parse!(body)}
      {:error, msg} -> {:error, msg}
    end
  end

  @spec create(Client.t, create_attrs) :: {:ok, Bucket.t()} | {:error, String.t()}
  def create(%Client{} = client, attrs) do
    url = Client.retrieve_storage_url(client, Endpoints.bucket_path())
    headers = Fetcher.apply_client_headers(client)

    url
    |> Fetcher.post(attrs, headers)
    |> case do
      {:ok, resp} -> {:ok, resp}
      {:error, msg} -> {:error, msg}
    end
  end

  @spec update(Client.t, bucket_id, update_attrs) ::
          {:ok, Bucket.t()} | {:error, String.t()}
  def update(%Client{} = client, id, attrs) do
    uri = Endpoints.bucket_path_with_id(id)
    url = Client.retrieve_storage_url(client, uri)
    headers = Fetcher.apply_client_headers(client)

    url
    |> Fetcher.put(attrs, headers)
    |> case do
      {:ok, message} -> {:ok, message}
      {:error, msg} -> {:error, msg}
    end
  end

  @spec empty(Client.t, bucket_id) ::
          {:ok, :successfully_emptied} | {:error, String.t()}
  def empty(%Client{} = client, id) do
    uri = Endpoints.bucket_path_to_empty(id)
    url = Client.retrieve_storage_url(client, uri)
    headers = Fetcher.apply_client_headers(client)

    url
    |> Fetcher.post(nil, headers)
    |> case do
      {:ok, _message} -> {:ok, :successfully_emptied}
      {:error, msg} -> {:error, msg}
    end
  end

  @spec delete(Client.t, bucket_id) ::
          {:ok, String.t()} | {:error, String.t()}
  def delete(%Client{} = client, id) do
    uri = Endpoints.bucket_path_with_id(id)
    url = Client.retrieve_storage_url(client, uri)
    headers = Fetcher.apply_client_headers(client)

    url
    |> Fetcher.delete(nil, headers)
    |> case do
      {:ok, body} -> {:ok, body}
      {:error, msg} -> {:error, msg}
    end
  end
end
