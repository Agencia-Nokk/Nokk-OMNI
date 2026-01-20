<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useNumberFormatter } from 'shared/composables/useNumberFormatter';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  currentPage: {
    type: Number,
    required: true,
  },
  totalItems: {
    type: Number,
    required: true,
  },
  itemsPerPage: {
    type: [Number, String],
    default: 15,
  },
  currentPageInfo: {
    type: String,
    default: '',
  },
  showPageSizeSelector: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:currentPage', 'update:itemsPerPage']);

const PAGE_SIZE_OPTIONS = [
  { value: 15, label: '15' },
  { value: 50, label: '50' },
  { value: 100, label: '100' },
  { value: 200, label: '200' },
  { value: 'all', label: null }, // label will be set from i18n
];

const { t } = useI18n();
const { formatCompactNumber, formatFullNumber } = useNumberFormatter();

const isPageSizeMenuOpen = ref(false);

const actualItemsPerPage = computed(() =>
  props.itemsPerPage === 'all' ? props.totalItems : props.itemsPerPage
);
const totalPages = computed(() =>
  Math.ceil(props.totalItems / actualItemsPerPage.value)
);
const startItem = computed(
  () => (props.currentPage - 1) * actualItemsPerPage.value + 1
);
const endItem = computed(() =>
  Math.min(startItem.value + actualItemsPerPage.value - 1, props.totalItems)
);
const isFirstPage = computed(() => props.currentPage === 1);
const isLastPage = computed(() => props.currentPage === totalPages.value);
const changePage = newPage => {
  if (newPage >= 1 && newPage <= totalPages.value) {
    emit('update:currentPage', newPage);
  }
};

const currentPageInformation = computed(() => {
  const translationKey = props.currentPageInfo || 'PAGINATION_FOOTER.SHOWING';
  return t(
    translationKey,
    {
      startItem: formatFullNumber(startItem.value),
      endItem: formatFullNumber(endItem.value),
      totalItems: formatCompactNumber(props.totalItems),
    },
    Number(props.totalItems)
  );
});

const pageInfo = computed(() => {
  return t(
    'PAGINATION_FOOTER.CURRENT_PAGE_INFO',
    {
      currentPage: '',
      totalPages: formatCompactNumber(totalPages.value),
    },
    Number(totalPages.value)
  );
});

const currentPageSizeLabel = computed(() => {
  return props.itemsPerPage === 'all'
    ? t('PAGINATION_FOOTER.ALL')
    : String(props.itemsPerPage);
});

const getOptionLabel = option => {
  return option.value === 'all' ? t('PAGINATION_FOOTER.ALL') : option.label;
};

const selectPageSize = value => {
  emit('update:itemsPerPage', value);
  emit('update:currentPage', 1);
  isPageSizeMenuOpen.value = false;
};

const togglePageSizeMenu = () => {
  isPageSizeMenuOpen.value = !isPageSizeMenuOpen.value;
};

const closePageSizeMenu = () => {
  isPageSizeMenuOpen.value = false;
};
</script>

<template>
  <div
    class="flex justify-between h-12 w-full max-w-[calc(60rem-3px)] outline outline-n-container outline-1 -outline-offset-1 mx-auto bg-n-solid-2 rounded-xl py-2 ltr:pl-4 rtl:pr-4 ltr:pr-3 rtl:pl-3 items-center before:absolute before:inset-x-0 before:-top-4 before:bg-gradient-to-t before:from-n-background before:from-10% before:dark:from-0% before:to-transparent before:h-4 before:pointer-events-none"
  >
    <div class="flex items-center gap-2">
      <span class="min-w-0 text-sm font-normal line-clamp-1 text-n-slate-11">
        {{ currentPageInformation }}
      </span>
      <div
        v-if="showPageSizeSelector"
        v-on-clickaway="closePageSizeMenu"
        class="relative"
      >
        <Button
          :label="currentPageSizeLabel"
          icon="i-lucide-chevron-down"
          size="xs"
          trailing-icon
          color="slate"
          variant="faded"
          class="!h-6 !px-2"
          @click="togglePageSizeMenu"
        />
        <div
          v-if="isPageSizeMenuOpen"
          class="absolute bottom-full mb-1 ltr:left-0 rtl:right-0 flex flex-col gap-0.5 bg-n-alpha-3 backdrop-blur-[100px] p-1 shadow-lg z-50 rounded-lg border border-n-weak dark:border-n-strong/50 min-w-[4rem]"
        >
          <Button
            v-for="option in PAGE_SIZE_OPTIONS"
            :key="option.value"
            :label="getOptionLabel(option)"
            :icon="option.value === itemsPerPage ? 'i-lucide-check' : ''"
            size="xs"
            variant="ghost"
            color="slate"
            class="!justify-between !px-2 !h-6 w-full"
            :class="{ '!bg-n-alpha-2': option.value === itemsPerPage }"
            @click="selectPageSize(option.value)"
          />
        </div>
      </div>
    </div>
    <div class="flex items-center gap-2">
      <Button
        icon="i-lucide-chevrons-left"
        variant="ghost"
        size="sm"
        color="slate"
        class="!w-8 !h-6"
        :disabled="isFirstPage"
        @click="changePage(1)"
      />
      <Button
        icon="i-lucide-chevron-left"
        variant="ghost"
        color="slate"
        size="sm"
        class="!w-8 !h-6"
        :disabled="isFirstPage"
        @click="changePage(currentPage - 1)"
      />
      <div class="inline-flex items-center gap-2 text-sm text-n-slate-11">
        <span class="px-3 tabular-nums py-0.5 bg-n-alpha-black2 rounded-md">
          {{ formatFullNumber(currentPage) }}
        </span>
        <span class="truncate">
          {{ pageInfo }}
        </span>
      </div>
      <Button
        icon="i-lucide-chevron-right"
        variant="ghost"
        color="slate"
        size="sm"
        class="!w-8 !h-6"
        :disabled="isLastPage"
        @click="changePage(currentPage + 1)"
      />
      <Button
        icon="i-lucide-chevrons-right"
        variant="ghost"
        color="slate"
        size="sm"
        class="!w-8 !h-6"
        :disabled="isLastPage"
        @click="changePage(totalPages)"
      />
    </div>
  </div>
</template>
