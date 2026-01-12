<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import ShopAPI from 'dashboard/api/shop';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'shared/components/Spinner.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const productId = route.params.productId;

const form = ref({
  name: '',
  description: '',
  price: 0,
  compare_at_price: null,
  stock_quantity: 0,
  sku: '',
  shop_category_id: null,
  track_inventory: true,
  active: true,
});

const categories = ref([]);
const existingImages = ref([]);
const imagesToDelete = ref([]);
const newImagePreviews = ref([]);
const newImageFiles = ref([]);
const variants = ref([]);
const variantsToDelete = ref([]);

// Drag & drop state
const isDragging = ref(false);
const existingDragStartIndex = ref(null);
const existingDragOverIndex = ref(null);
const newDragStartIndex = ref(null);
const newDragOverIndex = ref(null);
const reorderedImageIds = ref([]);

const uiFlags = ref({
  isFetching: false,
  isUpdating: false,
  isFetchingCategories: false,
});

const totalImagesCount = computed(() => {
  return existingImages.value.length + newImagePreviews.value.length;
});

const fetchProduct = async () => {
  uiFlags.value.isFetching = true;
  try {
    const response = await ShopAPI.getProduct(productId);
    const product = response.data;

    form.value = {
      name: product.name,
      description: product.description,
      price: product.price,
      compare_at_price: product.compare_at_price,
      stock_quantity: product.stock_quantity,
      sku: product.sku,
      shop_category_id: product.category?.id,
      track_inventory: product.track_inventory,
      active: product.active,
    };

    existingImages.value = product.images || [];
    reorderedImageIds.value = existingImages.value.map(img => img.id);

    // Load variants
    variants.value = (product.variants || []).map(v => ({
      id: v.id,
      name: v.name,
      price: v.price,
      stock_quantity: v.stock_quantity,
      sku: v.sku,
      active: v.active,
    }));
  } catch (error) {
    useAlert(error.message);
    router.push({ name: 'shop_products' });
  } finally {
    uiFlags.value.isFetching = false;
  }
};

const fetchCategories = async () => {
  uiFlags.value.isFetchingCategories = true;
  try {
    const response = await ShopAPI.getCategories();
    categories.value = response.data;
  } catch (error) {
    useAlert(error.message);
  } finally {
    uiFlags.value.isFetchingCategories = false;
  }
};

onMounted(() => {
  fetchProduct();
  fetchCategories();
});

const processFiles = files => {
  const validFiles = files.filter(file => file.type.startsWith('image/'));

  if (totalImagesCount.value + validFiles.length > 20) {
    useAlert(t('SHOP.PRODUCTS.FORM.IMAGES.MAX_LIMIT'));
    return;
  }

  if (validFiles.length < files.length) {
    useAlert(t('SHOP.PRODUCTS.FORM.IMAGES.INVALID_FILES'));
  }

  validFiles.forEach(file => {
    newImageFiles.value.push(file);

    const reader = new FileReader();
    reader.onload = e => {
      newImagePreviews.value.push(e.target.result);
    };
    reader.readAsDataURL(file);
  });
};

const handleImageUpload = event => {
  const files = Array.from(event.target.files);
  processFiles(files);
  event.target.value = '';
};

const handleDrop = event => {
  isDragging.value = false;
  const files = Array.from(event.dataTransfer.files);
  processFiles(files);
};

const removeExistingImage = (imageId, index) => {
  // eslint-disable-next-line no-alert
  if (window.confirm(t('SHOP.PRODUCTS.FORM.IMAGES.REMOVE_CONFIRM'))) {
    imagesToDelete.value.push(imageId);
    existingImages.value.splice(index, 1);
    reorderedImageIds.value = reorderedImageIds.value.filter(
      id => id !== imageId
    );
  }
};

const removeNewImage = index => {
  newImagePreviews.value.splice(index, 1);
  newImageFiles.value.splice(index, 1);
};

// Existing images drag & drop
const onExistingDragStart = (index, event) => {
  existingDragStartIndex.value = index;
  event.dataTransfer.effectAllowed = 'move';
};

const onExistingDragOver = index => {
  existingDragOverIndex.value = index;
};

const onExistingDragEnd = () => {
  if (
    existingDragStartIndex.value !== null &&
    existingDragOverIndex.value !== null &&
    existingDragStartIndex.value !== existingDragOverIndex.value
  ) {
    const [movedImage] = existingImages.value.splice(
      existingDragStartIndex.value,
      1
    );
    existingImages.value.splice(existingDragOverIndex.value, 0, movedImage);
    reorderedImageIds.value = existingImages.value.map(img => img.id);
  }
  existingDragStartIndex.value = null;
  existingDragOverIndex.value = null;
};

// New images drag & drop
const onNewDragStart = (index, event) => {
  newDragStartIndex.value = index;
  event.dataTransfer.effectAllowed = 'move';
};

const onNewDragOver = index => {
  newDragOverIndex.value = index;
};

const onNewDragEnd = () => {
  if (
    newDragStartIndex.value !== null &&
    newDragOverIndex.value !== null &&
    newDragStartIndex.value !== newDragOverIndex.value
  ) {
    const [movedPreview] = newImagePreviews.value.splice(
      newDragStartIndex.value,
      1
    );
    newImagePreviews.value.splice(newDragOverIndex.value, 0, movedPreview);

    const [movedFile] = newImageFiles.value.splice(newDragStartIndex.value, 1);
    newImageFiles.value.splice(newDragOverIndex.value, 0, movedFile);
  }
  newDragStartIndex.value = null;
  newDragOverIndex.value = null;
};

// Variant management
const addVariant = () => {
  variants.value.push({
    id: null,
    name: '',
    price: null,
    stock_quantity: 0,
    sku: '',
    active: true,
  });
};

const removeVariant = index => {
  const variant = variants.value[index];
  if (variant.id) {
    variantsToDelete.value.push(variant.id);
  }
  variants.value.splice(index, 1);
};

const handleSubmit = async () => {
  uiFlags.value.isUpdating = true;
  try {
    const formData = new FormData();

    // Adicionar campos do produto
    Object.keys(form.value).forEach(key => {
      if (form.value[key] !== null && form.value[key] !== '') {
        formData.append(`product[${key}]`, form.value[key]);
      }
    });

    // Adicionar novas imagens
    newImageFiles.value.forEach(file => {
      formData.append('product[images][]', file);
    });

    // Adicionar IDs de imagens para deletar
    imagesToDelete.value.forEach(id => {
      formData.append('product[delete_images][]', id);
    });

    // Adicionar ordem das imagens
    reorderedImageIds.value.forEach(id => {
      formData.append('product[image_order][]', id);
    });

    // Adicionar variantes
    variants.value.forEach((variant, index) => {
      if (variant.id) {
        formData.append(
          `product[variants_attributes][${index}][id]`,
          variant.id
        );
      }
      formData.append(
        `product[variants_attributes][${index}][name]`,
        variant.name
      );
      if (variant.price !== null && variant.price !== '') {
        formData.append(
          `product[variants_attributes][${index}][price]`,
          variant.price
        );
      }
      formData.append(
        `product[variants_attributes][${index}][stock_quantity]`,
        variant.stock_quantity
      );
      if (variant.sku) {
        formData.append(
          `product[variants_attributes][${index}][sku]`,
          variant.sku
        );
      }
      formData.append(
        `product[variants_attributes][${index}][active]`,
        variant.active
      );
    });

    // Adicionar variantes para deletar
    variantsToDelete.value.forEach(id => {
      formData.append('product[delete_variants][]', id);
    });

    await ShopAPI.updateProduct(productId, formData);
    useAlert(t('SHOP.PRODUCTS.FORM.UPDATE_SUCCESS'));
    router.push({ name: 'shop_products' });
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error updating product:', error, error.response);
    useAlert(
      error.response?.data?.errors?.join(', ') ||
        error.message ||
        t('SHOP.PRODUCTS.FORM.UPDATE_ERROR')
    );
  } finally {
    uiFlags.value.isUpdating = false;
  }
};

const confirmDelete = async () => {
  // eslint-disable-next-line no-alert
  if (!window.confirm(t('SHOP.PRODUCTS.FORM.DELETE_CONFIRM'))) {
    return;
  }

  try {
    await ShopAPI.deleteProduct(productId);
    useAlert(t('SHOP.PRODUCTS.FORM.DELETE_SUCCESS'));
    router.push({ name: 'shop_products' });
  } catch (error) {
    useAlert(error.message || t('SHOP.PRODUCTS.FORM.DELETE_ERROR'));
  }
};
</script>

<template>
  <div class="flex flex-col h-full">
    <div class="p-4 border-b border-slate-75 dark:border-slate-800">
      <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-25">
        {{ $t('SHOP.PRODUCTS.EDIT') }}
      </h2>
    </div>

    <div
      v-if="uiFlags.isFetching"
      class="flex items-center justify-center h-full"
    >
      <Spinner />
    </div>

    <div v-else class="flex-1 overflow-auto p-6">
      <div class="max-w-4xl mx-auto">
        <form @submit.prevent="handleSubmit">
          <div class="space-y-6">
            <!-- Upload de Múltiplas Imagens -->
            <div>
              <label
                class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
              >
                {{ $t('SHOP.PRODUCTS.FORM.IMAGES.LABEL') }}
              </label>
              <p class="text-xs text-slate-500 dark:text-slate-400 mb-3">
                {{ $t('SHOP.PRODUCTS.FORM.IMAGES.HELP') }}
              </p>

              <!-- Área de Drop -->
              <div
                class="border-2 border-dashed rounded-lg p-4 mb-3 transition-colors"
                :class="
                  isDragging
                    ? 'border-woot-500 bg-woot-50 dark:bg-woot-900/20'
                    : 'border-slate-300 dark:border-slate-600'
                "
                @dragover.prevent="isDragging = true"
                @dragleave.prevent="isDragging = false"
                @drop.prevent="handleDrop"
              >
                <div v-if="isDragging" class="text-center py-8">
                  <div
                    class="i-lucide-upload text-4xl text-woot-500 mx-auto mb-2"
                  />
                  <p class="text-sm text-woot-600 dark:text-woot-400">
                    {{ $t('SHOP.PRODUCTS.FORM.IMAGES.DROP_HERE') }}
                  </p>
                </div>

                <div v-else>
                  <!-- Grid de Imagens -->
                  <div
                    class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6 gap-2 sm:gap-3"
                  >
                    <!-- Imagens Existentes -->
                    <div
                      v-for="(image, index) in existingImages"
                      :key="'existing-' + image.id"
                      :draggable="true"
                      class="relative aspect-square border-2 border-slate-300 dark:border-slate-600 rounded-lg overflow-hidden group cursor-move"
                      @dragstart="onExistingDragStart(index, $event)"
                      @dragover.prevent="onExistingDragOver(index)"
                      @dragend="onExistingDragEnd"
                    >
                      <img
                        :src="image.thumbnail_url || image.url"
                        class="w-full h-full object-cover pointer-events-none"
                        :alt="$t('SHOP.PRODUCTS.FORM.IMAGES.LABEL')"
                      />
                      <button
                        type="button"
                        class="absolute top-1 right-1 bg-red-500 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity"
                        @click="removeExistingImage(image.id, index)"
                      >
                        <div class="i-lucide-x text-sm" />
                      </button>
                      <div
                        v-if="index === 0 && newImagePreviews.length === 0"
                        class="absolute bottom-0 left-0 right-0 bg-woot-500 text-white text-xs py-1 text-center"
                      >
                        {{ $t('SHOP.PRODUCTS.FORM.IMAGES.PRIMARY') }}
                      </div>
                      <div
                        v-if="
                          existingDragOverIndex === index &&
                          existingDragStartIndex !== index
                        "
                        class="absolute inset-0 bg-woot-500/30 border-2 border-woot-500"
                      />
                    </div>

                    <!-- Novas Imagens (Preview) -->
                    <div
                      v-for="(preview, index) in newImagePreviews"
                      :key="'new-' + index"
                      :draggable="true"
                      class="relative aspect-square border-2 border-green-500 rounded-lg overflow-hidden group cursor-move"
                      @dragstart="onNewDragStart(index, $event)"
                      @dragover.prevent="onNewDragOver(index)"
                      @dragend="onNewDragEnd"
                    >
                      <img
                        :src="preview"
                        class="w-full h-full object-cover pointer-events-none"
                        :alt="$t('SHOP.PRODUCTS.FORM.IMAGES.NEW')"
                      />
                      <button
                        type="button"
                        class="absolute top-1 right-1 bg-red-500 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity"
                        @click="removeNewImage(index)"
                      >
                        <div class="i-lucide-x text-sm" />
                      </button>
                      <div
                        class="absolute top-1 left-1 bg-green-500 text-white text-xs px-2 py-1 rounded"
                      >
                        {{ $t('SHOP.PRODUCTS.FORM.IMAGES.NEW') }}
                      </div>
                      <div
                        v-if="
                          newDragOverIndex === index &&
                          newDragStartIndex !== index
                        "
                        class="absolute inset-0 bg-woot-500/30 border-2 border-woot-500"
                      />
                    </div>

                    <!-- Botão Adicionar Imagem -->
                    <button
                      v-if="totalImagesCount < 20"
                      type="button"
                      class="aspect-square border-2 border-dashed border-slate-300 dark:border-slate-600 rounded-lg flex flex-col items-center justify-center cursor-pointer hover:border-woot-500 transition-colors"
                      @click="$refs.fileInput.click()"
                    >
                      <div class="i-lucide-plus text-2xl text-slate-400 mb-1" />
                      <span class="text-xs text-slate-500">{{
                        $t('SHOP.PRODUCTS.FORM.IMAGES.ADD')
                      }}</span>
                    </button>
                  </div>

                  <p
                    v-if="totalImagesCount === 0"
                    class="text-center py-6 text-slate-500 dark:text-slate-400"
                  >
                    <span class="i-lucide-upload text-2xl mb-2 block mx-auto" />
                    {{ $t('SHOP.PRODUCTS.FORM.IMAGES.DRAG_OR_CLICK') }}
                  </p>
                </div>
              </div>

              <input
                ref="fileInput"
                type="file"
                accept="image/*"
                multiple
                class="hidden"
                @change="handleImageUpload"
              />

              <p class="text-xs text-slate-500 dark:text-slate-400">
                {{
                  $t('SHOP.PRODUCTS.FORM.IMAGES.COUNTER', {
                    count: totalImagesCount,
                  })
                }}
                &bull; {{ $t('SHOP.PRODUCTS.FORM.IMAGES.REORDER_HINT') }} &bull;
                {{ $t('SHOP.PRODUCTS.FORM.IMAGES.PRIMARY_HINT') }}
              </p>
            </div>

            <!-- Categoria -->
            <div>
              <label
                class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
              >
                {{ $t('SHOP.PRODUCTS.FORM.CATEGORY.LABEL') }}
              </label>
              <select
                v-model="form.shop_category_id"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md bg-white dark:bg-slate-800"
                required
              >
                <option :value="null">
                  {{ $t('SHOP.PRODUCTS.FORM.CATEGORY.PLACEHOLDER') }}
                </option>
                <option
                  v-for="category in categories"
                  :key="category.id"
                  :value="category.id"
                >
                  {{ category.name }}
                </option>
              </select>
            </div>

            <!-- Nome -->
            <div>
              <label
                class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
              >
                {{ $t('SHOP.PRODUCTS.FORM.NAME.LABEL') }}
              </label>
              <input
                v-model="form.name"
                type="text"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100"
                :placeholder="$t('SHOP.PRODUCTS.FORM.NAME.PLACEHOLDER')"
                required
              />
            </div>

            <!-- Descrição -->
            <div>
              <label
                class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
              >
                {{ $t('SHOP.PRODUCTS.FORM.DESCRIPTION.LABEL') }}
              </label>
              <textarea
                v-model="form.description"
                rows="4"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100"
                :placeholder="$t('SHOP.PRODUCTS.FORM.DESCRIPTION.PLACEHOLDER')"
              />
            </div>

            <!-- Preço -->
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label
                  class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
                >
                  {{ $t('SHOP.PRODUCTS.FORM.PRICE.LABEL') }}
                </label>
                <input
                  v-model.number="form.price"
                  type="number"
                  step="0.01"
                  min="0"
                  class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100"
                  required
                />
              </div>

              <div>
                <label
                  class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
                >
                  {{ $t('SHOP.PRODUCTS.FORM.COMPARE_AT_PRICE.LABEL') }}
                </label>
                <input
                  v-model.number="form.compare_at_price"
                  type="number"
                  step="0.01"
                  min="0"
                  class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100"
                />
              </div>
            </div>

            <!-- SKU -->
            <div>
              <label
                class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
              >
                {{ $t('SHOP.PRODUCTS.FORM.SKU.LABEL') }}
              </label>
              <input
                v-model="form.sku"
                type="text"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100"
                :placeholder="$t('SHOP.PRODUCTS.FORM.SKU.PLACEHOLDER')"
              />
            </div>

            <!-- Estoque -->
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label
                  class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
                >
                  {{ $t('SHOP.PRODUCTS.FORM.STOCK.LABEL') }}
                </label>
                <input
                  v-model.number="form.stock_quantity"
                  type="number"
                  min="0"
                  class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100"
                  required
                />
              </div>

              <div class="flex items-center pt-8">
                <input
                  id="track-inventory"
                  v-model="form.track_inventory"
                  type="checkbox"
                  class="mr-2"
                />
                <label
                  for="track-inventory"
                  class="text-sm text-slate-700 dark:text-slate-300"
                >
                  {{ $t('SHOP.PRODUCTS.FORM.TRACK_INVENTORY.LABEL') }}
                </label>
              </div>
            </div>

            <!-- Ativo -->
            <div class="flex items-center">
              <input
                id="active"
                v-model="form.active"
                type="checkbox"
                class="mr-2"
              />
              <label
                for="active"
                class="text-sm text-slate-700 dark:text-slate-300"
              >
                {{ $t('SHOP.PRODUCTS.FORM.ACTIVE.LABEL') }}
              </label>
            </div>

            <!-- Variantes -->
            <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
              <div class="flex items-center justify-between mb-4">
                <div>
                  <h3
                    class="text-lg font-medium text-slate-900 dark:text-slate-100"
                  >
                    {{ $t('SHOP.PRODUCTS.FORM.VARIANTS.TITLE') }}
                  </h3>
                  <p class="text-sm text-slate-600 dark:text-slate-400">
                    {{ $t('SHOP.PRODUCTS.FORM.VARIANTS.DESCRIPTION') }}
                  </p>
                </div>
                <Button
                  variant="smooth"
                  icon="i-lucide-plus"
                  size="small"
                  @click="addVariant"
                >
                  {{ $t('SHOP.PRODUCTS.FORM.VARIANTS.ADD') }}
                </Button>
              </div>

              <div v-if="variants.length > 0" class="space-y-3">
                <div
                  v-for="(variant, index) in variants"
                  :key="variant.id || `new-${index}`"
                  class="flex items-start gap-3 p-4 bg-slate-50 dark:bg-slate-800 rounded-lg"
                >
                  <div class="flex-1 grid grid-cols-4 gap-3">
                    <div>
                      <label
                        class="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1"
                      >
                        {{ $t('SHOP.PRODUCTS.FORM.VARIANTS.NAME_LABEL') }}
                      </label>
                      <input
                        v-model="variant.name"
                        type="text"
                        :placeholder="
                          $t('SHOP.PRODUCTS.FORM.VARIANTS.NAME_PLACEHOLDER')
                        "
                        class="w-full px-2 py-1.5 text-sm border border-slate-300 dark:border-slate-600 rounded-md bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                        required
                      />
                    </div>
                    <div>
                      <label
                        class="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1"
                      >
                        {{ $t('SHOP.PRODUCTS.FORM.VARIANTS.PRICE_LABEL') }}
                      </label>
                      <input
                        v-model.number="variant.price"
                        type="number"
                        step="0.01"
                        min="0"
                        :placeholder="
                          $t('SHOP.PRODUCTS.FORM.VARIANTS.PRICE_PLACEHOLDER')
                        "
                        class="w-full px-2 py-1.5 text-sm border border-slate-300 dark:border-slate-600 rounded-md bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                      />
                    </div>
                    <div>
                      <label
                        class="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1"
                      >
                        {{ $t('SHOP.PRODUCTS.FORM.VARIANTS.STOCK_LABEL') }}
                      </label>
                      <input
                        v-model.number="variant.stock_quantity"
                        type="number"
                        min="0"
                        class="w-full px-2 py-1.5 text-sm border border-slate-300 dark:border-slate-600 rounded-md bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                        required
                      />
                    </div>
                    <div>
                      <label
                        class="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1"
                      >
                        {{ $t('SHOP.PRODUCTS.FORM.VARIANTS.SKU_LABEL') }}
                      </label>
                      <input
                        v-model="variant.sku"
                        type="text"
                        :placeholder="
                          $t('SHOP.PRODUCTS.FORM.VARIANTS.SKU_PLACEHOLDER')
                        "
                        class="w-full px-2 py-1.5 text-sm border border-slate-300 dark:border-slate-600 rounded-md bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                      />
                    </div>
                  </div>
                  <Button
                    variant="smooth"
                    color-scheme="alert"
                    icon="i-lucide-trash-2"
                    size="small"
                    @click="removeVariant(index)"
                  />
                </div>
              </div>

              <div
                v-else
                class="text-center py-8 text-slate-500 dark:text-slate-400 text-sm"
              >
                {{ $t('SHOP.PRODUCTS.FORM.VARIANTS.EMPTY') }}
              </div>
            </div>

            <!-- Botões -->
            <div
              class="flex justify-between pt-6 border-t border-slate-200 dark:border-slate-700"
            >
              <Button
                variant="smooth"
                color-scheme="alert"
                icon="i-lucide-trash-2"
                @click="confirmDelete"
              >
                {{ $t('SHOP.PRODUCTS.FORM.DELETE_PRODUCT') }}
              </Button>

              <div class="flex space-x-3">
                <Button
                  :label="$t('SHOP.PRODUCTS.FORM.BUTTONS.CANCEL')"
                  variant="outline"
                  @click="$router.push({ name: 'shop_products' })"
                />
                <Button
                  type="submit"
                  :label="$t('SHOP.PRODUCTS.FORM.BUTTONS.UPDATE')"
                  :is-loading="uiFlags.isUpdating"
                />
              </div>
            </div>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>
