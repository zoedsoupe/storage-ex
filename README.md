# Supabase Storage

[Storage](https://supabase.com/docs/guides/storage) implementation for the `supabase_potion` SDK in Elixir.

## Installation

```elixir
def deps do
  [
    {:supabase_potion, "~> 0.4"},
    {:supabase_storage, "~> 0.3"}
  ]
end
```

## Usage

Firstly you need to initialize your Supabase client(s) as can be found on the [supabase_potion documentation](https://github.com/zoedsoupe/supabase-ex?tab=readme-ov-file#starting-a-client)

Now you can pass the Client to the `Supabase.Storage` functions:

```elixir
iex> Supabase.Storage.list_buckets(%Supabase.Client{})  
```
