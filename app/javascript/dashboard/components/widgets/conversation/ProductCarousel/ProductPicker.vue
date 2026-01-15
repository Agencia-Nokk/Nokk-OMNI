<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import ShopAPI from 'dashboard/api/shop';
import Spinner from 'shared/components/Spinner.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  selectedProducts: {
    type: Array,
    default: () => [],
  },
  text: {
    type: String,
    default: '',
  },
  maxProducts: {
    type: Number,
    default: 10,
  },
});

const emit = defineEmits(['update:selectedProducts', 'update:text']);

const { t } = useI18n();
const query = ref('');
const products = ref([]);
const isLoading = ref(false);

const filteredProducts = computed(() => {
  if (!query.value) return products.value;
  const searchLower = query.value.toLowerCase();
  return products.value.filter(
    product =>
      product.name.toLowerCase().includes(searchLower) ||
      product.description?.toLowerCase().includes(searchLower)
  );
});

const isSelected = productId => {
  return props.selectedProducts.some(p => p.id === productId);
};

const canSelectMore = computed(() => {
  return props.selectedProducts.length < props.maxProducts;
});

const selectionCount = computed(() => {
  return `${props.selectedProducts.length}/${props.maxProducts}`;
});

const toggleProduct = product => {
  const currentSelected = [...props.selectedProducts];
  const index = currentSelected.findIndex(p => p.id === product.id);

  if (index >= 0) {
    currentSelected.splice(index, 1);
  } else if (canSelectMore.value) {
    currentSelected.push(product);
  }

  emit('update:selectedProducts', currentSelected);
};

const formatPrice = price => {
  if (!price) return '';
  return `R$ ${Number(price).toFixed(2).replace('.', ',')}`;
};

const getProductImage = product => {
  if (product.images && product.images.length > 0) {
    return product.images[0].url || product.images[0];
  }
  return null;
};

const fetchProducts = async () => {
  isLoading.value = true;
  try {
    const response = await ShopAPI.getProducts({ active_only: true });
    products.value = response.data || [];
  } catch {
    products.value = [];
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  fetchProducts();
});
</script>

<template>
  <div class="w-full">
    <!-- Message text input -->
    <div class="mb-4">
      <label class="block text-sm font-medium text-n-slate-12 mb-1">
        {{ t('PRODUCT_CAROUSEL.PREVIEW.MESSAGE_LABEL') }}
      </label>
      <input
        :value="text"
        type="text"
        :placeholder="t('PRODUCT_CAROUSEL.PREVIEW.MESSAGE_PLACEHOLDER')"
        class="reset-base w-full h-10 px-3 bg-n-alpha-black2 rounded-lg text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand"
        @input="emit('update:text', $event.target.value)"
      />
    </div>

    <!-- Search -->
    <div class="flex gap-2 mb-2.5">
      <div
        class="flex flex-1 gap-1 items-center px-2.5 py-0 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak hover:outline-n-slate-6 focus-within:outline-n-brand"
      >
        <fluent-icon icon="search" class="text-n-slate-12" size="16" />
        <input
          v-model="query"
          type="search"
          :placeholder="t('PRODUCT_CAROUSEL.SEARCH_PLACEHOLDER')"
          class="reset-base w-full h-9 bg-transparent text-n-slate-12 text-sm outline-0"
        />
      </div>
      <div
        class="flex items-center justify-center px-3 h-9 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak text-sm text-n-slate-11"
      >
        {{ selectionCount }}
      </div>
    </div>

    <!-- Loading -->
    <div
      v-if="isLoading"
      class="flex items-center justify-center py-12 bg-n-background outline outline-1 outline-n-container rounded-lg"
    >
      <Spinner size="large" />
    </div>

    <!-- Empty State -->
    <div
      v-else-if="filteredProducts.length === 0"
      class="py-12 text-center bg-n-background outline outline-1 outline-n-container rounded-lg"
    >
      <div v-if="query && products.length">
        <p class="text-n-slate-11">
          {{ t('PRODUCT_CAROUSEL.NO_PRODUCTS_SEARCH') }}
          <strong>{{ query }}</strong>
        </p>
      </div>
      <div v-else class="space-y-2">
        <Icon
          icon="i-lucide-package-x"
          class="size-10 text-n-slate-9 mx-auto"
        />
        <p class="text-n-slate-11">
          {{ t('PRODUCT_CAROUSEL.NO_PRODUCTS') }}
        </p>
      </div>
    </div>

    <!-- Products List -->
    <div
      v-else
      class="bg-n-background outline outline-1 outline-n-container rounded-lg max-h-80 overflow-y-auto p-2.5"
    >
      <div v-for="(product, i) in filteredProducts" :key="product.id">
        <button
          type="button"
          class="flex items-center gap-3 p-2.5 w-full text-left rounded-lg transition-colors"
          :class="[
            isSelected(product.id) ? 'bg-n-brand/10' : 'hover:bg-n-alpha-2',
            !isSelected(product.id) &&
              !canSelectMore &&
              'opacity-50 cursor-not-allowed',
          ]"
          :disabled="!isSelected(product.id) && !canSelectMore"
          @click="toggleProduct(product)"
        >
          <!-- Checkbox -->
          <div
            class="flex items-center justify-center size-5 rounded border-2 transition-colors flex-shrink-0"
            :class="
              isSelected(product.id)
                ? 'bg-n-brand border-n-brand'
                : 'border-n-slate-6'
            "
          >
            <Icon
              v-if="isSelected(product.id)"
              icon="i-lucide-check"
              class="size-3 text-white"
            />
          </div>

          <!-- Image -->
          <div
            class="size-12 rounded-lg overflow-hidden bg-n-alpha-3 flex-shrink-0"
          >
            <img
              v-if="getProductImage(product)"
              :src="getProductImage(product)"
              :alt="product.name"
              class="w-full h-full object-cover"
            />
            <div v-else class="w-full h-full flex items-center justify-center">
              <Icon icon="i-lucide-image" class="size-5 text-n-slate-9" />
            </div>
          </div>

          <!-- Info -->
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-n-slate-12 truncate">
              {{ product.name }}
            </p>
            <p class="text-xs text-n-slate-11 truncate">
              {{ product.description || t('PRODUCT_CAROUSEL.NO_DESCRIPTION') }}
            </p>
          </div>

          <!-- Price -->
          <div class="text-right flex-shrink-0">
            <p class="text-sm font-semibold text-n-slate-12">
              {{ formatPrice(product.price) }}
            </p>
          </div>
        </button>
        <hr
          v-if="i !== filteredProducts.length - 1"
          class="border-b border-solid border-n-weak my-1 mx-auto max-w-[95%]"
        />
      </div>
    </div>
  </div>
</template>
