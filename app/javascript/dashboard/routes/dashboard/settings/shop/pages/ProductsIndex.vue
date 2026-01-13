<script setup>
import { ref, computed, onMounted, onActivated } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import ShopAPI from 'dashboard/api/shop';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'shared/components/Spinner.vue';
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';

const router = useRouter();
const { t } = useI18n();

const products = ref([]);
const categories = ref([]);
const searchQuery = ref('');
const currentPage = ref(1);
const itemsPerPage = 12;

const selectedCategory = ref(null);
const selectedStatus = ref(null);

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

// Options for SingleSelect components
const categoryOptions = computed(() => {
  return categories.value.map(category => ({
    id: category.id,
    name: category.name,
  }));
});

const statusOptions = computed(() => [
  { id: 'active', name: t('SHOP.PRODUCTS.FILTER_ACTIVE') },
  { id: 'inactive', name: t('SHOP.PRODUCTS.FILTER_INACTIVE') },
]);

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
  if (selectedCategory.value) {
    result = result.filter(
      product => product.category?.id === selectedCategory.value.id
    );
  }

  // Active filter
  if (selectedStatus.value) {
    const isActive = selectedStatus.value.id === 'active';
    result = result.filter(product => product.active === isActive);
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
    selectedCategory.value !== null ||
    selectedStatus.value !== null
  );
});

const debouncedSearch = () => {
  clearTimeout(searchTimeout);
  searchTimeout = setTimeout(() => {
    currentPage.value = 1;
  }, 300);
};

const clearSearch = () => {
  searchQuery.value = '';
  currentPage.value = 1;
};

const clearFilters = () => {
  searchQuery.value = '';
  selectedCategory.value = null;
  selectedStatus.value = null;
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
    <div class="flex items-center justify-between p-4 border-b border-n-weak">
      <div>
        <h2 class="text-xl font-semibold text-n-slate-12">
          {{ $t('SHOP.PRODUCTS.TITLE') }}
        </h2>
        <p class="text-sm text-n-slate-11">
          {{ $t('SHOP.PRODUCTS.DESCRIPTION') }}
        </p>
      </div>
      <Button
        :label="$t('SHOP.PRODUCTS.NEW')"
        icon="i-lucide-plus"
        @click="$router.push({ name: 'shop_products_new' })"
      />
    </div>

    <div class="p-4 border-b border-n-weak space-y-3">
      <div class="relative w-full">
        <span
          class="absolute i-lucide-search size-4 top-2.5 left-3 text-n-slate-10"
        />
        <input
          v-model="searchQuery"
          type="search"
          class="reset-base w-full h-10 py-2 pl-10 pr-10 text-sm focus:outline-none border-none rounded-xl bg-n-alpha-black2 dark:bg-n-solid-1 text-n-slate-12 placeholder:text-n-slate-10"
          :placeholder="$t('SHOP.PRODUCTS.SEARCH_PLACEHOLDER')"
          @input="debouncedSearch"
        />
        <button
          v-if="searchQuery"
          type="button"
          class="absolute top-2.5 right-3 text-n-slate-10 hover:text-n-slate-12 transition-colors"
          @click="clearSearch"
        >
          <span class="i-lucide-x size-4" />
        </button>
      </div>

      <div class="flex flex-wrap items-center gap-3">
        <SingleSelect
          v-model="selectedCategory"
          :options="categoryOptions"
          :placeholder="$t('SHOP.PRODUCTS.ALL_CATEGORIES')"
          placeholder-icon="i-lucide-folder"
          :search-placeholder="$t('SHOP.PRODUCTS.SEARCH_CATEGORY')"
        />

        <SingleSelect
          v-model="selectedStatus"
          :options="statusOptions"
          :placeholder="$t('SHOP.PRODUCTS.FILTER_ALL')"
          placeholder-icon="i-lucide-filter"
          disable-search
        />

        <button
          v-if="hasActiveFilters"
          type="button"
          class="h-8 px-3 text-sm text-n-blue-text hover:bg-n-alpha-2 rounded-lg flex items-center gap-1.5 transition-colors"
          @click="clearFilters"
        >
          <span class="i-lucide-x size-3.5" />
          <span class="hidden sm:inline">{{
            $t('SHOP.PRODUCTS.CLEAR_FILTERS')
          }}</span>
        </button>

        <div class="ml-auto flex items-center gap-1.5 text-sm text-n-slate-11">
          <span class="i-lucide-package size-4" />
          <span>{{
            $t('SHOP.PRODUCTS.PRODUCTS_COUNT', {
              count: filteredProducts.length,
            })
          }}</span>
        </div>
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
      <span class="i-lucide-shopping-bag text-6xl text-n-slate-9 mb-4" />
      <h3 class="text-lg font-medium text-n-slate-12 mb-2">
        {{
          hasActiveFilters
            ? $t('SHOP.PRODUCTS.NO_PRODUCTS_FOUND')
            : $t('SHOP.PRODUCTS.EMPTY_STATE.TITLE')
        }}
      </h3>
      <p class="text-sm text-n-slate-11 mb-6 text-center max-w-md">
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
          class="bg-n-solid-2 rounded-xl border border-n-weak overflow-hidden hover:shadow-lg hover:border-n-slate-6 transition-all cursor-pointer"
          @click="editProduct(product.id)"
        >
          <div class="aspect-square bg-n-alpha-2 relative">
            <img
              v-if="product.primary_image && product.primary_image.url"
              :src="product.primary_image.url"
              :alt="product.name"
              class="w-full h-full object-cover"
            />
            <div v-else class="flex items-center justify-center h-full">
              <span class="i-lucide-image text-6xl text-n-slate-9" />
            </div>

            <div
              v-if="product.images && product.images.length > 1"
              class="absolute bottom-2 right-2 px-2 py-1 bg-n-solid-3/90 backdrop-blur-sm text-n-slate-12 text-xs rounded-md flex items-center gap-1"
            >
              <span class="i-lucide-images size-3" />
              {{ product.images.length }}
            </div>

            <div
              v-if="!product.active"
              class="absolute top-2 right-2 px-2 py-1 bg-n-solid-3/90 backdrop-blur-sm text-n-slate-11 text-xs rounded-md"
            >
              {{ $t('SHOP.PRODUCTS.INACTIVE') }}
            </div>
            <div
              v-if="product.on_sale"
              class="absolute top-2 left-2 px-2 py-1 bg-n-brand text-white text-xs rounded-md font-medium"
            >
              -{{ product.discount_percentage }}%
            </div>
          </div>

          <div class="p-4">
            <h3 class="font-medium text-n-slate-12 truncate mb-1">
              {{ product.name }}
            </h3>
            <p class="text-sm text-n-slate-11 line-clamp-2 mb-2">
              {{ product.description }}
            </p>

            <div class="flex items-center justify-between">
              <div>
                <span class="text-lg font-semibold text-n-blue-text">
                  {{ formatCurrency(product.price) }}
                </span>
                <span
                  v-if="product.compare_at_price"
                  class="text-sm text-n-slate-10 line-through ml-2"
                >
                  {{ formatCurrency(product.compare_at_price) }}
                </span>
              </div>

              <div class="flex items-center gap-1 text-sm text-n-slate-11">
                <span v-if="product.variants && product.variants.length > 0">
                  {{
                    $t('SHOP.PRODUCTS.VARIANTS_COUNT', {
                      count: product.variants.length,
                    })
                  }}
                </span>
                <template v-else-if="product.track_inventory">
                  <span class="i-lucide-package size-3.5" />
                  <span>{{ product.stock_quantity }}</span>
                </template>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div
        v-if="totalPages > 1"
        class="flex items-center justify-center gap-1.5 mt-6 pb-4"
      >
        <button
          type="button"
          class="size-8 flex items-center justify-center text-sm border border-n-weak rounded-lg hover:bg-n-alpha-2 text-n-slate-11 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          :disabled="currentPage === 1"
          @click="goToPage(currentPage - 1)"
        >
          <span class="i-lucide-chevron-left size-4" />
        </button>

        <template v-for="page in visiblePages" :key="page">
          <span v-if="page === '...'" class="px-2 text-n-slate-10">...</span>
          <button
            v-else
            type="button"
            class="size-8 flex items-center justify-center text-sm border rounded-lg transition-colors"
            :class="
              page === currentPage
                ? 'border-n-brand bg-n-brand text-white'
                : 'border-n-weak hover:bg-n-alpha-2 text-n-slate-11'
            "
            @click="goToPage(page)"
          >
            {{ page }}
          </button>
        </template>

        <button
          type="button"
          class="size-8 flex items-center justify-center text-sm border border-n-weak rounded-lg hover:bg-n-alpha-2 text-n-slate-11 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          :disabled="currentPage === totalPages"
          @click="goToPage(currentPage + 1)"
        >
          <span class="i-lucide-chevron-right size-4" />
        </button>
      </div>
    </div>
  </div>
</template>
