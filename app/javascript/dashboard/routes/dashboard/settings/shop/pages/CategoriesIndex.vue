<script setup>
import { ref, onMounted, onActivated } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import ShopAPI from 'dashboard/api/shop';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'shared/components/Spinner.vue';

const { t } = useI18n();

const categories = ref([]);
const showModal = ref(false);
const editingCategory = ref(null);
const form = ref({
  name: '',
  description: '',
  active: true,
});

// Image state
const imageFile = ref(null);
const imagePreview = ref(null);
const existingImageUrl = ref(null);
const isDragging = ref(false);

// Drag & drop reorder state
const dragStartIndex = ref(null);
const dragOverIndex = ref(null);

const uiFlags = ref({
  isFetching: false,
  isSaving: false,
});

const fetchCategories = async () => {
  uiFlags.value.isFetching = true;
  try {
    const response = await ShopAPI.getCategories();
    categories.value = response.data;
  } catch (error) {
    useAlert(error.message);
  } finally {
    uiFlags.value.isFetching = false;
  }
};

onMounted(() => {
  fetchCategories();
});

onActivated(() => {
  fetchCategories();
});

const openCreateModal = () => {
  editingCategory.value = null;
  form.value = {
    name: '',
    description: '',
    active: true,
  };
  imageFile.value = null;
  imagePreview.value = null;
  existingImageUrl.value = null;
  showModal.value = true;
};

const openEditModal = category => {
  editingCategory.value = category;
  form.value = {
    name: category.name,
    description: category.description,
    active: category.active,
  };
  imageFile.value = null;
  imagePreview.value = null;
  existingImageUrl.value = category.image?.url || null;
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
  editingCategory.value = null;
  imageFile.value = null;
  imagePreview.value = null;
  existingImageUrl.value = null;
};

const handleImageSelect = event => {
  const file = event.target.files[0];
  if (file && file.type.startsWith('image/')) {
    imageFile.value = file;
    const reader = new FileReader();
    reader.onload = e => {
      imagePreview.value = e.target.result;
    };
    reader.readAsDataURL(file);
  }
};

const handleImageDrop = event => {
  isDragging.value = false;
  const file = event.dataTransfer.files[0];
  if (file && file.type.startsWith('image/')) {
    imageFile.value = file;
    const reader = new FileReader();
    reader.onload = e => {
      imagePreview.value = e.target.result;
    };
    reader.readAsDataURL(file);
  }
};

const removeImage = () => {
  imageFile.value = null;
  imagePreview.value = null;
  existingImageUrl.value = null;
};

const handleSubmit = async () => {
  uiFlags.value.isSaving = true;
  try {
    const formData = new FormData();
    formData.append('category[name]', form.value.name);
    formData.append('category[description]', form.value.description || '');
    formData.append('category[active]', form.value.active);

    if (imageFile.value) {
      formData.append('category[image]', imageFile.value);
    }

    if (editingCategory.value) {
      await ShopAPI.updateCategory(editingCategory.value.id, formData);
      useAlert(t('SHOP.CATEGORIES.UPDATE_SUCCESS'));
    } else {
      await ShopAPI.createCategory(formData);
      useAlert(t('SHOP.CATEGORIES.CREATE_SUCCESS'));
    }
    await fetchCategories();
    closeModal();
  } catch (error) {
    useAlert(error.message || t('SHOP.CATEGORIES.SAVE_ERROR'));
  } finally {
    uiFlags.value.isSaving = false;
  }
};

const deleteCategory = async categoryId => {
  // eslint-disable-next-line no-alert, no-restricted-globals
  if (!window.confirm(t('SHOP.CATEGORIES.DELETE_CONFIRM'))) return;

  try {
    await ShopAPI.deleteCategory(categoryId);
    useAlert(t('SHOP.CATEGORIES.DELETE_SUCCESS'));
    await fetchCategories();
  } catch (error) {
    useAlert(error.message || t('SHOP.CATEGORIES.DELETE_ERROR'));
  }
};

// Drag & drop reorder
const onDragStart = (index, event) => {
  dragStartIndex.value = index;
  event.dataTransfer.effectAllowed = 'move';
};

const onDragOver = index => {
  dragOverIndex.value = index;
};

const onDragEnd = async () => {
  if (
    dragStartIndex.value !== null &&
    dragOverIndex.value !== null &&
    dragStartIndex.value !== dragOverIndex.value
  ) {
    // Reorder locally
    const [movedCategory] = categories.value.splice(dragStartIndex.value, 1);
    categories.value.splice(dragOverIndex.value, 0, movedCategory);

    // Update positions
    const updates = categories.value.map((cat, index) => ({
      id: cat.id,
      position: index,
    }));

    // Save new positions to backend
    try {
      // eslint-disable-next-line no-restricted-syntax
      for (const update of updates) {
        // eslint-disable-next-line no-await-in-loop
        await ShopAPI.updateCategory(update.id, {
          category: { position: update.position },
        });
      }
      // Update local positions
      categories.value.forEach((cat, index) => {
        cat.position = index;
      });
    } catch (error) {
      useAlert(t('SHOP.CATEGORIES.REORDER_ERROR'));
      await fetchCategories();
    }
  }

  dragStartIndex.value = null;
  dragOverIndex.value = null;
};
</script>

<template>
  <div class="flex flex-col h-full">
    <div
      class="flex items-center justify-between p-4 border-b border-slate-75 dark:border-slate-800"
    >
      <div>
        <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-25">
          {{ $t('SHOP.CATEGORIES.TITLE') }}
        </h2>
        <p class="text-sm text-slate-600 dark:text-slate-400">
          {{ $t('SHOP.CATEGORIES.DESCRIPTION') }}
        </p>
      </div>
      <Button
        :label="$t('SHOP.CATEGORIES.NEW')"
        icon="i-lucide-plus"
        @click="openCreateModal"
      />
    </div>

    <div
      v-if="uiFlags.isFetching"
      class="flex items-center justify-center h-full"
    >
      <Spinner />
    </div>

    <div
      v-else-if="!categories.length"
      class="flex flex-col items-center justify-center h-full p-8"
    >
      <div class="i-lucide-folder text-6xl text-slate-400 mb-4" />
      <h3 class="text-lg font-medium text-slate-700 dark:text-slate-300 mb-2">
        {{ $t('SHOP.CATEGORIES.EMPTY_STATE.TITLE') }}
      </h3>
      <p
        class="text-sm text-slate-600 dark:text-slate-400 mb-6 text-center max-w-md"
      >
        {{ $t('SHOP.CATEGORIES.EMPTY_STATE.MESSAGE') }}
      </p>
      <Button
        :label="$t('SHOP.CATEGORIES.NEW')"
        icon="i-lucide-plus"
        @click="openCreateModal"
      />
    </div>

    <div v-else class="flex-1 overflow-auto p-4">
      <p class="text-sm text-slate-500 dark:text-slate-400 mb-4">
        <span class="i-lucide-grip-vertical inline-block mr-1" />
        {{ $t('SHOP.CATEGORIES.REORDER_HINT') }}
      </p>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div
          v-for="(category, index) in categories"
          :key="category.id"
          :draggable="true"
          class="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 overflow-hidden hover:shadow-lg transition-shadow cursor-move"
          :class="{
            'ring-2 ring-woot-500':
              dragOverIndex === index && dragStartIndex !== index,
          }"
          @dragstart="onDragStart(index, $event)"
          @dragover.prevent="onDragOver(index)"
          @dragend="onDragEnd"
        >
          <div class="aspect-video bg-slate-100 dark:bg-slate-800 relative">
            <img
              v-if="category.image?.url"
              :src="category.image.thumbnail_url || category.image.url"
              :alt="category.name"
              class="w-full h-full object-cover"
            />
            <div v-else class="flex items-center justify-center h-full">
              <div class="i-lucide-folder text-4xl text-slate-400" />
            </div>
            <div
              class="absolute top-2 left-2 px-2 py-1 bg-slate-900/60 text-white text-xs rounded flex items-center"
            >
              <div class="i-lucide-grip-vertical size-3 mr-1" />
              {{ category.position + 1 }}
            </div>
          </div>

          <div class="p-4">
            <div class="flex items-start justify-between mb-2">
              <div class="flex-1">
                <h3 class="font-medium text-slate-900 dark:text-slate-100 mb-1">
                  {{ category.name }}
                </h3>
                <p
                  class="text-sm text-slate-600 dark:text-slate-400 line-clamp-2"
                >
                  {{
                    category.description || $t('SHOP.CATEGORIES.NO_DESCRIPTION')
                  }}
                </p>
              </div>
              <div
                v-if="!category.active"
                class="px-2 py-1 bg-slate-200 dark:bg-slate-700 text-slate-600 dark:text-slate-400 text-xs rounded ml-2"
              >
                {{ $t('SHOP.CATEGORIES.INACTIVE') }}
              </div>
            </div>

            <div
              class="flex items-center justify-between pt-3 border-t border-slate-200 dark:border-slate-700"
            >
              <span class="text-sm text-slate-600 dark:text-slate-400">
                {{
                  $t('SHOP.CATEGORIES.PRODUCTS_COUNT', {
                    count: category.products_count || 0,
                  })
                }}
              </span>
              <div class="flex space-x-2">
                <Button
                  variant="smooth"
                  size="small"
                  icon="i-lucide-pencil"
                  @click.stop="openEditModal(category)"
                />
                <Button
                  variant="smooth"
                  size="small"
                  color-scheme="alert"
                  icon="i-lucide-trash-2"
                  @click.stop="deleteCategory(category.id)"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <woot-modal v-if="showModal" :show="showModal" :on-close="closeModal">
      <div class="p-6">
        <h3
          class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-4"
        >
          {{
            editingCategory
              ? $t('SHOP.CATEGORIES.EDIT')
              : $t('SHOP.CATEGORIES.NEW')
          }}
        </h3>
        <form @submit.prevent="handleSubmit">
          <div class="space-y-4">
            <div>
              <label
                class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
              >
                {{ $t('SHOP.CATEGORIES.FORM.IMAGE_LABEL') }}
              </label>
              <div
                class="relative aspect-video border-2 border-dashed rounded-lg overflow-hidden transition-colors"
                :class="
                  isDragging
                    ? 'border-woot-500 bg-woot-50 dark:bg-woot-900/20'
                    : 'border-slate-300 dark:border-slate-600'
                "
                @dragover.prevent="isDragging = true"
                @dragleave.prevent="isDragging = false"
                @drop.prevent="handleImageDrop"
              >
                <img
                  v-if="imagePreview || existingImageUrl"
                  :src="imagePreview || existingImageUrl"
                  :alt="$t('SHOP.CATEGORIES.FORM.IMAGE_LABEL')"
                  class="w-full h-full object-cover"
                />
                <div
                  v-else
                  class="absolute inset-0 flex flex-col items-center justify-center"
                >
                  <div class="i-lucide-upload text-3xl text-slate-400 mb-2" />
                  <p class="text-sm text-slate-500">
                    {{ $t('SHOP.CATEGORIES.FORM.IMAGE_DRAG') }}
                  </p>
                </div>

                <button
                  v-if="imagePreview || existingImageUrl"
                  type="button"
                  class="absolute top-2 right-2 bg-red-500 text-white rounded-full p-1.5"
                  @click="removeImage"
                >
                  <div class="i-lucide-x size-4" />
                </button>

                <input
                  type="file"
                  accept="image/*"
                  class="absolute inset-0 opacity-0 cursor-pointer"
                  @change="handleImageSelect"
                />
              </div>
            </div>

            <div>
              <label
                class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
              >
                {{ $t('SHOP.CATEGORIES.FORM.NAME_LABEL') }}
              </label>
              <input
                v-model="form.name"
                type="text"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100"
                :placeholder="$t('SHOP.CATEGORIES.FORM.NAME_PLACEHOLDER')"
                required
              />
            </div>

            <div>
              <label
                class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
              >
                {{ $t('SHOP.CATEGORIES.FORM.DESCRIPTION_LABEL') }}
              </label>
              <textarea
                v-model="form.description"
                rows="3"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100"
                :placeholder="
                  $t('SHOP.CATEGORIES.FORM.DESCRIPTION_PLACEHOLDER')
                "
              />
            </div>

            <div class="flex items-center">
              <input
                id="category-active"
                v-model="form.active"
                type="checkbox"
                class="mr-2"
              />
              <label
                for="category-active"
                class="text-sm text-slate-700 dark:text-slate-300"
              >
                {{ $t('SHOP.CATEGORIES.FORM.ACTIVE_LABEL') }}
              </label>
            </div>

            <div
              class="flex justify-end space-x-3 pt-4 border-t border-slate-200 dark:border-slate-700"
            >
              <Button
                :label="$t('SHOP.CATEGORIES.FORM.CANCEL')"
                variant="outline"
                @click="closeModal"
              />
              <Button
                type="submit"
                :label="
                  editingCategory
                    ? $t('SHOP.CATEGORIES.FORM.UPDATE')
                    : $t('SHOP.CATEGORIES.FORM.CREATE')
                "
                :is-loading="uiFlags.isSaving"
              />
            </div>
          </div>
        </form>
      </div>
    </woot-modal>
  </div>
</template>
