<script setup>
import { ref, computed, onMounted, onActivated } from 'vue';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import ShopAPI from 'dashboard/api/shop';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'shared/components/Spinner.vue';

const router = useRouter();

const products = ref([]);
const categories = ref([]);
const searchQuery = ref('');
const currentPage = ref(1);
const itemsPerPage = 12;

const filters = ref({
  categoryId: null,
  active: null,
});

const uiFlags = ref({
  isFetching: false,
});

let searchTimeout = null;

const fetchProducts = async () => {
  uiFlags.value.isFetching = true;
  try {
    const response = await ShopAPI.getProducts();
    products.value = response.data;
  } catch (error) {
    useAlert(error.message);
  } finally {
    uiFlags.value.isFetching = false;
  }
};

const fetchCategories = async () => {
  try {
    const response = await ShopAPI.getCategories();
    categories.value = response.data;
  } catch (error) {
    // Silent fail for categories
  }
};

onMounted(() => {
  fetchProducts();
  fetchCategories();
});

onActivated(() => {
  fetchProducts();
});

// Filtered products based on search and filters
const filteredProducts = computed(() => {
  let result = products.value;

  // Search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase();
    result = result.filter(
      product =>
        product.name.toLowerCase().includes(query) ||
        (product.sku && product.sku.toLowerCase().includes(query)) ||
        (product.description &&
          product.description.toLowerCase().includes(query))
    );
  }

  // Category filter
  if (filters.value.categoryId) {
    result = result.filter(
      product => product.category?.id === filters.value.categoryId
    );
  }

  // Active filter
  if (filters.value.active !== null) {
    result = result.filter(product => product.active === filters.value.active);
  }

  return result;
});

// Pagination
const totalPages = computed(() => {
  return Math.ceil(filteredProducts.value.length / itemsPerPage);
});

const paginatedProducts = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage;
  const end = start + itemsPerPage;
  return filteredProducts.value.slice(start, end);
});

const visiblePages = computed(() => {
  const pages = [];
  const total = totalPages.value;
  const current = currentPage.value;

  if (total <= 7) {
    for (let i = 1; i <= total; i += 1) {
      pages.push(i);
    }
  } else {
    pages.push(1);

    if (current > 3) {
      pages.push('...');
    }

    const start = Math.max(2, current - 1);
    const end = Math.min(total - 1, current + 1);

    for (let i = start; i <= end; i += 1) {
      pages.push(i);
    }

    if (current < total - 2) {
      pages.push('...');
    }

    pages.push(total);
  }

  return pages;
});

const hasActiveFilters = computed(() => {
  return (
    searchQuery.value ||
    filters.value.categoryId !== null ||
    filters.value.active !== null
  );
});

const debouncedSearch = () => {
  clearTimeout(searchTimeout);
  searchTimeout = setTimeout(() => {
    currentPage.value = 1;
  }, 300);
};

const applyFilters = () => {
  currentPage.value = 1;
};

const clearSearch = () => {
  searchQuery.value = '';
  currentPage.value = 1;
};

const clearFilters = () => {
  searchQuery.value = '';
  filters.value = {
    categoryId: null,
    active: null,
  };
  currentPage.value = 1;
};

const goToPage = page => {
  if (page >= 1 && page <= totalPages.value) {
    currentPage.value = page;
  }
};

const editProduct = productId => {
  router.push({ name: 'shop_products_edit', params: { productId } });
};

const formatCurrency = value => {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(value);
};
</script>

<template>
  <div class="flex flex-col h-full">
    <div
      class="flex items-center justify-between p-4 border-b border-slate-75 dark:border-slate-800"
    >
      <div>
        <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-25">
          {{ $t('SHOP.PRODUCTS.TITLE') }}
        </h2>
        <p class="text-sm text-slate-600 dark:text-slate-400">
          {{ $t('SHOP.PRODUCTS.DESCRIPTION') }}
        </p>
      </div>
      <Button
        :label="$t('SHOP.PRODUCTS.NEW')"
        icon="i-lucide-plus"
        @click="$router.push({ name: 'shop_products_new' })"
      />
    </div>

    <div
      class="p-4 border-b border-slate-75 dark:border-slate-800 bg-slate-50 dark:bg-slate-900 space-y-3"
    >
      <div class="relative w-full">
        <input
          v-model="searchQuery"
          type="text"
          class="w-full px-3 py-2 text-sm border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100"
          :placeholder="$t('SHOP.PRODUCTS.SEARCH_PLACEHOLDER')"
          @input="debouncedSearch"
        />
        <button
          v-if="searchQuery"
          class="absolute inset-y-0 right-3 flex items-center"
          @click="clearSearch"
        >
          <div class="i-lucide-x size-4 text-slate-400 hover:text-slate-600" />
        </button>
      </div>

      <div class="flex flex-wrap items-center gap-2">
        <select
          v-model="filters.categoryId"
          class="custom-select h-9 pl-3 pr-8 text-sm border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100 cursor-pointer"
          @change="applyFilters"
        >
          <option :value="null">
            {{ $t('SHOP.PRODUCTS.ALL_CATEGORIES') }}
          </option>
          <option
            v-for="category in categories"
            :key="category.id"
            :value="category.id"
          >
            {{ category.name }}
          </option>
        </select>

        <select
          v-model="filters.active"
          class="custom-select h-9 pl-3 pr-8 text-sm border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100 cursor-pointer"
          @change="applyFilters"
        >
          <option :value="null">
            {{ $t('SHOP.PRODUCTS.FILTER_ALL') }}
          </option>
          <option :value="true">
            {{ $t('SHOP.PRODUCTS.FILTER_ACTIVE') }}
          </option>
          <option :value="false">
            {{ $t('SHOP.PRODUCTS.FILTER_INACTIVE') }}
          </option>
        </select>

        <button
          v-if="hasActiveFilters"
          class="px-3 py-2 text-sm text-woot-600 hover:text-woot-700 flex items-center gap-1"
          @click="clearFilters"
        >
          <div class="i-lucide-x size-4" />
          <span class="hidden sm:inline">{{
            $t('SHOP.PRODUCTS.CLEAR_FILTERS')
          }}</span>
        </button>

        <span class="text-sm text-slate-600 dark:text-slate-400 ml-auto">
          {{
            $t('SHOP.PRODUCTS.PRODUCTS_COUNT', {
              count: filteredProducts.length,
            })
          }}
        </span>
      </div>
    </div>

    <div
      v-if="uiFlags.isFetching"
      class="flex items-center justify-center h-full"
    >
      <Spinner />
    </div>

    <div
      v-else-if="!filteredProducts.length"
      class="flex flex-col items-center justify-center h-full p-8"
    >
      <div class="i-lucide-shopping-bag text-6xl text-slate-400 mb-4" />
      <h3 class="text-lg font-medium text-slate-700 dark:text-slate-300 mb-2">
        {{
          hasActiveFilters
            ? $t('SHOP.PRODUCTS.NO_PRODUCTS_FOUND')
            : $t('SHOP.PRODUCTS.EMPTY_STATE.TITLE')
        }}
      </h3>
      <p
        class="text-sm text-slate-600 dark:text-slate-400 mb-6 text-center max-w-md"
      >
        {{
          hasActiveFilters
            ? $t('SHOP.PRODUCTS.TRY_DIFFERENT_FILTERS')
            : $t('SHOP.PRODUCTS.EMPTY_STATE.MESSAGE')
        }}
      </p>
      <Button
        v-if="!hasActiveFilters"
        :label="$t('SHOP.PRODUCTS.NEW')"
        icon="i-lucide-plus"
        @click="$router.push({ name: 'shop_products_new' })"
      />
      <Button
        v-else
        :label="$t('SHOP.PRODUCTS.CLEAR_FILTERS')"
        variant="outline"
        @click="clearFilters"
      />
    </div>

    <div v-else class="flex-1 overflow-auto p-4">
      <div
        class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4"
      >
        <div
          v-for="product in paginatedProducts"
          :key="product.id"
          class="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 overflow-hidden hover:shadow-lg transition-shadow cursor-pointer"
          @click="editProduct(product.id)"
        >
          <div class="aspect-square bg-slate-100 dark:bg-slate-800 relative">
            <img
              v-if="product.primary_image && product.primary_image.url"
              :src="product.primary_image.url"
              :alt="product.name"
              class="w-full h-full object-cover"
            />
            <div v-else class="flex items-center justify-center h-full">
              <div class="i-lucide-image text-6xl text-slate-400" />
            </div>

            <div
              v-if="product.images && product.images.length > 1"
              class="absolute bottom-2 right-2 px-2 py-1 bg-slate-900/80 text-white text-xs rounded flex items-center"
            >
              <div class="i-lucide-images text-xs mr-1" />
              {{ product.images.length }}
            </div>

            <div
              v-if="!product.active"
              class="absolute top-2 right-2 px-2 py-1 bg-slate-900/80 text-white text-xs rounded"
            >
              {{ $t('SHOP.PRODUCTS.INACTIVE') }}
            </div>
            <div
              v-if="product.on_sale"
              class="absolute top-2 left-2 px-2 py-1 bg-woot-500 text-white text-xs rounded font-medium"
            >
              -{{ product.discount_percentage }}%
            </div>
          </div>

          <div class="p-4">
            <h3
              class="font-medium text-slate-900 dark:text-slate-100 truncate mb-1"
            >
              {{ product.name }}
            </h3>
            <p
              class="text-sm text-slate-600 dark:text-slate-400 line-clamp-2 mb-2"
            >
              {{ product.description }}
            </p>

            <div class="flex items-center justify-between">
              <div>
                <span class="text-lg font-semibold text-woot-500">
                  {{ formatCurrency(product.price) }}
                </span>
                <span
                  v-if="product.compare_at_price"
                  class="text-sm text-slate-500 line-through ml-2"
                >
                  {{ formatCurrency(product.compare_at_price) }}
                </span>
              </div>

              <div class="text-sm text-slate-600 dark:text-slate-400">
                <span v-if="product.variants && product.variants.length > 0">
                  {{
                    $t('SHOP.PRODUCTS.VARIANTS_COUNT', {
                      count: product.variants.length,
                    })
                  }}
                </span>
                <span v-else-if="product.track_inventory">
                  {{ product.stock_quantity }}
                  {{ $t('SHOP.PRODUCTS.IN_STOCK') }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div
        v-if="totalPages > 1"
        class="flex items-center justify-center gap-2 mt-6 pb-4"
      >
        <button
          class="px-3 py-2 text-sm border border-slate-300 dark:border-slate-600 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 disabled:opacity-50 disabled:cursor-not-allowed"
          :disabled="currentPage === 1"
          @click="goToPage(currentPage - 1)"
        >
          <div class="i-lucide-chevron-left size-4" />
        </button>

        <template v-for="page in visiblePages" :key="page">
          <span v-if="page === '...'" class="px-2 text-slate-500">...</span>
          <button
            v-else
            class="px-3 py-2 text-sm border rounded-lg"
            :class="
              page === currentPage
                ? 'border-woot-500 bg-woot-500 text-white'
                : 'border-slate-300 dark:border-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800'
            "
            @click="goToPage(page)"
          >
            {{ page }}
          </button>
        </template>

        <button
          class="px-3 py-2 text-sm border border-slate-300 dark:border-slate-600 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 disabled:opacity-50 disabled:cursor-not-allowed"
          :disabled="currentPage === totalPages"
          @click="goToPage(currentPage + 1)"
        >
          <div class="i-lucide-chevron-right size-4" />
        </button>
      </div>
    </div>
  </div>
</template>

<style>
.custom-select {
  -webkit-appearance: none;
  -moz-appearance: none;
  appearance: none;
  background-image: url("data:image/svg+xml;charset=UTF-8,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%236b7280' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3e%3cpolyline points='6 9 12 15 18 9'%3e%3c/polyline%3e%3c/svg%3e");
  background-repeat: no-repeat;
  background-position: right 0.5rem center;
  background-size: 1rem;
}
</style>
