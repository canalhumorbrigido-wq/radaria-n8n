-- RadarIA | Supabase pgvector
-- La dimensión 3072 corresponde a models/gemini-embedding-2.
-- Si cambias el modelo de embeddings (p. ej. nomic-embed-text en Ollama = 768),
-- debes cambiar la dimensión y reindexar todo.

create extension if not exists vector;

create table if not exists documents (
  id bigserial primary key,
  content text,
  metadata jsonb,
  embedding vector(3072)
);

create or replace function match_documents (
  query_embedding vector(3072),
  match_count int default 5,
  filter jsonb default '{}'::jsonb
) returns table (
  id bigint,
  content text,
  metadata jsonb,
  similarity float
) language plpgsql as $$
begin
  return query
  select documents.id, documents.content, documents.metadata,
         1 - (documents.embedding <=> query_embedding) as similarity
  from documents
  where documents.metadata @> filter
  order by documents.embedding <=> query_embedding
  limit match_count;
end;
$$;
