import { useEffect, useState } from "react";
import { apiGet } from "../../lib/api";
import { PLACEHOLDER_RECIPES } from "./placeholderRecipes";
import {
  EMPTY_FILTERS,
  hasActiveFilters,
  type RecipeCard,
  type RecipeFilters,
} from "./types";

type Status = "loading" | "success" | "error";

interface RecipesResponse {
  data: RecipeCard[];
  meta?: { after_id?: string | null; offset?: number };
}

const PAGE_SIZE = 20;

function buildFilterQuery(filters: RecipeFilters) {
  return {
    category: filters.category || undefined,
    cuisine: filters.cuisine.length ? filters.cuisine.join(",") : undefined,
    difficulty: filters.difficulty || undefined,
    dietary: filters.dietary.length ? filters.dietary.join(",") : undefined,
    min_time: filters.minTime,
    max_time: filters.maxTime,
  };
}

export function useRecipes(filters: RecipeFilters = EMPTY_FILTERS) {
  const [recipes, setRecipes] = useState<RecipeCard[]>([]);
  const [status, setStatus] = useState<Status>("loading");
  const [afterId, setAfterId] = useState<string | null>(null);
  const [offset, setOffset] = useState(0);
  const [hasMore, setHasMore] = useState(false);

  const isSearch = filters.q.trim().length > 0;
  const isFiltered = !isSearch && hasActiveFilters(filters);
  const filterKey = JSON.stringify(filters);

  useEffect(() => {
    let cancelled = false;
    setStatus("loading");
    setRecipes([]);
    setAfterId(null);
    setOffset(0);

    async function fetchInitial() {
      try {
        // let data: RecipeCard[];
        // let meta: RecipesResponse["meta"];

        if (isSearch) {
          // const res = await apiGet<RecipesResponse>(
          //   "/recipes/search",
          //   {
          //     q: filters.q.trim(),
          //     ...buildFilterQuery(filters),
          //     limit: PAGE_SIZE,
          //     offset: 0,
          //   },
          //   { auth: false },
          // );
          // data = res.data;
          // meta = res.meta;
        } else if (isFiltered) {
          // const res = await apiGet<RecipesResponse>(
          //   "/recipes",
          //   { ...buildFilterQuery(filters), limit: PAGE_SIZE },
          //   { auth: false },
          // );
          // data = res.data;
          // meta = res.meta;
        } else {
          // const res = await apiGet<RecipesResponse>(
          //   "/recipes/trending",
          //   { limit: PAGE_SIZE },
          //   { auth: false },
          // );
          // data = res.data;
          // meta = undefined;
        }

        if (cancelled) return;

        // TEST-ONLY: fall back to placeholder data when the backend has
        // nothing to return (e.g. unseeded dev DB), so the grid can still
        // be reviewed. Remove once the backend is reliably seeded.
        setRecipes(PLACEHOLDER_RECIPES);
        setHasMore(false);
        setStatus("success");
        return;

        /*
        if (data.length === 0) {
          setRecipes(PLACEHOLDER_RECIPES);
          setHasMore(false);
          setStatus("success");
          return;
        }

        setRecipes(data);
        if (isSearch) {
          setOffset(data.length);
          setHasMore(data.length === PAGE_SIZE);
        } else if (isFiltered) {
          setAfterId(meta?.after_id ?? null);
          setHasMore(Boolean(meta?.after_id) && data.length === PAGE_SIZE);
        } else {
          setHasMore(false);
        }
        setStatus("success");
        */
      } catch {
        if (!cancelled) setStatus("error");
      }
    }

    fetchInitial();
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filterKey]);

  const loadMore = async () => {
    try {
      if (isSearch) {
        const res = await apiGet<RecipesResponse>(
          "/recipes/search",
          {
            q: filters.q.trim(),
            ...buildFilterQuery(filters),
            limit: PAGE_SIZE,
            offset,
          },
          { auth: false },
        );
        setRecipes((prev) => [...prev, ...res.data]);
        setOffset((prev) => prev + res.data.length);
        setHasMore(res.data.length === PAGE_SIZE);
      } else if (isFiltered && afterId) {
        const res = await apiGet<RecipesResponse>(
          "/recipes",
          { ...buildFilterQuery(filters), limit: PAGE_SIZE, after_id: afterId },
          { auth: false },
        );
        setRecipes((prev) => [...prev, ...res.data]);
        setAfterId(res.meta?.after_id ?? null);
        setHasMore(
          Boolean(res.meta?.after_id) && res.data.length === PAGE_SIZE,
        );
      }
    } catch {
      setHasMore(false);
    }
  };

  return { recipes, status, hasMore, loadMore };
}
