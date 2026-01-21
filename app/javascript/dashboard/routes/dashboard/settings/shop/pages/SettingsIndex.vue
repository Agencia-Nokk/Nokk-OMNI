<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import ShopAPI from 'dashboard/api/shop';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import SettingsSection from 'dashboard/components/SettingsSection.vue';

const { t } = useI18n();

// Preview modal state
const showPreviewModal = ref(false);
const previewMode = ref('desktop');
const previewIframe = ref(null);
const previewKey = ref(0);

// Active tab
const selectedTabIndex = ref(0);

const tabs = computed(() => [
  { key: 'basic', name: t('SHOP.SETTINGS.TABS.BASIC') },
  { key: 'display', name: t('SHOP.SETTINGS.TABS.DISPLAY') },
  { key: 'appearance', name: t('SHOP.SETTINGS.TABS.APPEARANCE') },
  { key: 'delivery', name: t('SHOP.SETTINGS.TABS.DELIVERY') },
]);

const selectedTabKey = computed(() => tabs.value[selectedTabIndex.value]?.key);

const isLoading = ref(true);
const isSaving = ref(false);
const settings = ref({
  name: '',
  description: '',
  whatsapp_number: '',
  order_message_template: '',
  contact_email: '',
  business_hours: '',
  enabled: true,
  show_out_of_stock: true,
  show_prices: true,
  default_sort: 'newest',
  products_per_page: 12,
  minimum_order_value: null,
  minimum_order_message: '',
  delivery_info: '',
  delivery_areas: '',
  pickup_info: '',
  primary_color: '#1F93FF',
  background_color: '#FFFFFF',
  text_color: '#1F2937',
  secondary_color: '#6B7280',
  header_style: 'minimal',
  show_categories_bar: true,
  products_per_row: 3,
  card_style: 'shadow',
  show_featured_badge: true,
  featured_badge_text: 'Destaque',
  address: '',
  footer_text: '',
});

const publicUrl = ref('');
const logoUrl = ref(null);
const bannerUrl = ref(null);
const logoFile = ref(null);
const bannerFile = ref(null);

const sortOptions = computed(() => [
  { value: 'newest', label: t('SHOP.SETTINGS.DISPLAY.SORT_OPTIONS.NEWEST') },
  { value: 'oldest', label: t('SHOP.SETTINGS.DISPLAY.SORT_OPTIONS.OLDEST') },
  {
    value: 'price_asc',
    label: t('SHOP.SETTINGS.DISPLAY.SORT_OPTIONS.PRICE_ASC'),
  },
  {
    value: 'price_desc',
    label: t('SHOP.SETTINGS.DISPLAY.SORT_OPTIONS.PRICE_DESC'),
  },
  {
    value: 'name_asc',
    label: t('SHOP.SETTINGS.DISPLAY.SORT_OPTIONS.NAME_ASC'),
  },
  {
    value: 'name_desc',
    label: t('SHOP.SETTINGS.DISPLAY.SORT_OPTIONS.NAME_DESC'),
  },
]);

const headerStyles = computed(() => [
  {
    value: 'minimal',
    label: t('SHOP.SETTINGS.APPEARANCE.HEADER_STYLES.MINIMAL'),
  },
  {
    value: 'with_banner',
    label: t('SHOP.SETTINGS.APPEARANCE.HEADER_STYLES.WITH_BANNER'),
  },
]);

const productsPerRowOptions = computed(() => [
  { value: 2, label: t('SHOP.SETTINGS.LAYOUT.COLUMNS_2') },
  { value: 3, label: t('SHOP.SETTINGS.LAYOUT.COLUMNS_3') },
  { value: 4, label: t('SHOP.SETTINGS.LAYOUT.COLUMNS_4') },
]);

const cardStyles = computed(() => [
  { value: 'shadow', label: t('SHOP.SETTINGS.LAYOUT.CARD_SHADOW') },
  { value: 'border', label: t('SHOP.SETTINGS.LAYOUT.CARD_BORDER') },
  { value: 'minimal', label: t('SHOP.SETTINGS.LAYOUT.CARD_MINIMAL') },
]);

const productsPerPageOptions = [8, 12, 16, 24, 32, 48];

const previewContainerClass = computed(() => {
  switch (previewMode.value) {
    case 'mobile':
      return 'w-[375px] h-[667px]';
    default:
      return 'w-full h-full';
  }
});

const previewIframeSrc = computed(() => {
  const baseUrl = window.location.origin;
  return `${baseUrl}${publicUrl.value}?preview=1&t=${previewKey.value}`;
});

function sendSettingsToPreview() {
  if (!previewIframe.value?.contentWindow) return;

  previewIframe.value.contentWindow.postMessage(
    {
      type: 'SHOP_PREVIEW_UPDATE',
      settings: {
        primary_color: settings.value.primary_color,
        background_color: settings.value.background_color,
        text_color: settings.value.text_color,
        secondary_color: settings.value.secondary_color,
        show_prices: settings.value.show_prices,
        show_featured_badge: settings.value.show_featured_badge,
        featured_badge_text: settings.value.featured_badge_text,
        card_style: settings.value.card_style,
        products_per_row: settings.value.products_per_row,
        name: settings.value.name,
      },
    },
    '*'
  );
}

watch(
  settings,
  () => {
    if (showPreviewModal.value) {
      sendSettingsToPreview();
    }
  },
  { deep: true }
);

async function fetchSettings() {
  isLoading.value = true;
  try {
    const response = await ShopAPI.getSettings();
    Object.assign(settings.value, response.data);
    publicUrl.value = response.data.public_url;
    logoUrl.value = response.data.logo_url;
    bannerUrl.value = response.data.banner_url;
  } catch (error) {
    useAlert(t('SHOP.SETTINGS.FETCH_ERROR'));
  } finally {
    isLoading.value = false;
  }
}

async function saveSettings() {
  isSaving.value = true;
  try {
    const formData = new FormData();

    Object.keys(settings.value).forEach(key => {
      if (settings.value[key] !== null && settings.value[key] !== undefined) {
        formData.append(`setting[${key}]`, settings.value[key]);
      }
    });

    if (logoFile.value) {
      formData.append('setting[logo]', logoFile.value);
    }
    if (bannerFile.value) {
      formData.append('setting[banner]', bannerFile.value);
    }

    const response = await ShopAPI.updateSettings(formData);
    Object.assign(settings.value, response.data);
    logoUrl.value = response.data.logo_url;
    bannerUrl.value = response.data.banner_url;

    useAlert(t('SHOP.SETTINGS.SAVE_SUCCESS'));
  } catch (error) {
    useAlert(t('SHOP.SETTINGS.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
}

function onLogoChange(event) {
  const file = event.target.files[0];
  if (file) {
    logoFile.value = file;
    logoUrl.value = URL.createObjectURL(file);
  }
}

function onBannerChange(event) {
  const file = event.target.files[0];
  if (file) {
    bannerFile.value = file;
    bannerUrl.value = URL.createObjectURL(file);
  }
}

function removeLogo() {
  logoFile.value = null;
  logoUrl.value = null;
}

function removeBanner() {
  bannerFile.value = null;
  bannerUrl.value = null;
}

function copyPublicUrl() {
  const fullUrl = `${window.location.origin}${publicUrl.value}`;
  navigator.clipboard.writeText(fullUrl);
  useAlert(t('SHOP.SETTINGS.URL_COPIED'));
}

function openPreview() {
  previewKey.value = Date.now();
  showPreviewModal.value = true;
}

function onPreviewLoad() {
  setTimeout(sendSettingsToPreview, 500);
}

function onTabChange(index) {
  selectedTabIndex.value = index;
}

onMounted(() => {
  fetchSettings();
});
</script>

<template>
  <div class="flex flex-col w-full h-full overflow-auto">
    <!-- Loading State -->
    <div v-if="isLoading" class="flex items-center justify-center flex-1 py-20">
      <Spinner :size="32" />
    </div>

    <div v-else class="w-full">
      <!-- Header Section -->
      <div class="flex flex-col gap-4 px-8 pt-6 pb-4">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-4">
            <h1 class="text-xl font-medium tracking-tight text-n-slate-12">
              {{ $t('SHOP.SETTINGS.TITLE') }}
            </h1>
            <span
              class="px-2.5 py-1 text-xs font-medium rounded-full"
              :class="
                settings.enabled
                  ? 'bg-n-teal-3 text-n-teal-11'
                  : 'bg-n-slate-3 text-n-slate-11'
              "
            >
              {{
                settings.enabled
                  ? $t('SHOP.SETTINGS.STATUS.ONLINE')
                  : $t('SHOP.SETTINGS.STATUS.OFFLINE')
              }}
            </span>
          </div>

          <div class="flex items-center gap-2">
            <Button
              variant="hollow"
              :label="$t('SHOP.SETTINGS.PREVIEW.TOGGLE')"
              icon="i-lucide-eye"
              @click="openPreview"
            />
            <Button
              :label="$t('SHOP.SETTINGS.SAVE')"
              icon="i-lucide-save"
              :is-loading="isSaving"
              @click="saveSettings"
            />
          </div>
        </div>

        <!-- Store URL Box -->
        <div class="flex items-center gap-3 p-3 rounded-lg bg-n-alpha-2">
          <span class="text-sm text-n-slate-11">
            {{ $t('SHOP.SETTINGS.STORE_URL') }}:
          </span>
          <code class="text-sm font-mono text-n-slate-12">{{ publicUrl }}</code>
          <div class="flex items-center gap-1 ml-auto">
            <Button
              variant="hollow"
              size="small"
              icon="i-lucide-copy"
              :label="$t('SHOP.SETTINGS.COPY')"
              @click="copyPublicUrl"
            />
            <a :href="publicUrl" target="_blank" rel="noopener noreferrer">
              <Button
                variant="hollow"
                size="small"
                icon="i-lucide-external-link"
                :label="$t('SHOP.SETTINGS.OPEN')"
              />
            </a>
          </div>
        </div>
      </div>

      <!-- Tabs -->
      <woot-tabs
        class="px-8 [&_ul]:p-0"
        :index="selectedTabIndex"
        :border="false"
        @change="onTabChange"
      >
        <woot-tabs-item
          v-for="(tab, index) in tabs"
          :key="tab.key"
          :index="index"
          :name="tab.name"
          :show-badge="false"
          is-compact
        />
      </woot-tabs>

      <!-- Content Area -->
      <section class="mx-auto w-full max-w-6xl px-8">
        <!-- Tab: Basic Info -->
        <template v-if="selectedTabKey === 'basic'">
          <SettingsSection
            :title="$t('SHOP.SETTINGS.BASIC_INFO.TITLE')"
            :sub-title="$t('SHOP.SETTINGS.DESCRIPTION')"
          >
            <div class="flex flex-col gap-4">
              <label class="block">
                <span class="text-sm font-medium text-n-slate-12 mb-1.5 block">
                  {{ $t('SHOP.SETTINGS.BASIC_INFO.NAME_LABEL') }}
                </span>
                <input
                  v-model="settings.name"
                  type="text"
                  class="w-full"
                  :placeholder="$t('SHOP.SETTINGS.BASIC_INFO.NAME_PLACEHOLDER')"
                />
              </label>

              <label class="block">
                <span class="text-sm font-medium text-n-slate-12 mb-1.5 block">
                  {{ $t('SHOP.SETTINGS.BASIC_INFO.DESCRIPTION_LABEL') }}
                </span>
                <textarea
                  v-model="settings.description"
                  rows="3"
                  class="w-full"
                  :placeholder="
                    $t('SHOP.SETTINGS.BASIC_INFO.DESCRIPTION_PLACEHOLDER')
                  "
                />
              </label>

              <!-- Logo e Banner -->
              <div class="grid grid-cols-2 gap-6">
                <div>
                  <span class="text-sm font-medium text-n-slate-12 mb-2 block">
                    {{ $t('SHOP.SETTINGS.BASIC_INFO.LOGO_LABEL') }}
                  </span>
                  <div
                    class="aspect-square w-24 rounded-xl bg-n-alpha-2 flex items-center justify-center overflow-hidden border-2 border-dashed border-n-weak relative group"
                  >
                    <img
                      v-if="logoUrl"
                      :src="logoUrl"
                      alt="Logo"
                      class="w-full h-full object-cover"
                    />
                    <div v-else class="i-lucide-image size-8 text-n-slate-9" />
                    <div
                      class="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 flex items-center justify-center gap-2 transition-opacity"
                    >
                      <label
                        class="p-2 bg-white rounded-lg cursor-pointer hover:bg-n-alpha-2"
                      >
                        <div class="i-lucide-upload size-4 text-n-slate-12" />
                        <input
                          type="file"
                          accept="image/*"
                          class="hidden"
                          @change="onLogoChange"
                        />
                      </label>
                      <button
                        v-if="logoUrl"
                        class="p-2 bg-n-ruby-9 rounded-lg hover:bg-n-ruby-10"
                        @click="removeLogo"
                      >
                        <div class="i-lucide-trash-2 size-4 text-white" />
                      </button>
                    </div>
                  </div>
                </div>

                <div>
                  <span class="text-sm font-medium text-n-slate-12 mb-2 block">
                    {{ $t('SHOP.SETTINGS.BASIC_INFO.BANNER_LABEL') }}
                  </span>
                  <div
                    class="aspect-video w-full max-w-[200px] rounded-xl bg-n-alpha-2 flex items-center justify-center overflow-hidden border-2 border-dashed border-n-weak relative group"
                  >
                    <img
                      v-if="bannerUrl"
                      :src="bannerUrl"
                      alt="Banner"
                      class="w-full h-full object-cover"
                    />
                    <div v-else class="i-lucide-image size-8 text-n-slate-9" />
                    <div
                      class="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 flex items-center justify-center gap-2 transition-opacity"
                    >
                      <label
                        class="p-2 bg-white rounded-lg cursor-pointer hover:bg-n-alpha-2"
                      >
                        <div class="i-lucide-upload size-4 text-n-slate-12" />
                        <input
                          type="file"
                          accept="image/*"
                          class="hidden"
                          @change="onBannerChange"
                        />
                      </label>
                      <button
                        v-if="bannerUrl"
                        class="p-2 bg-n-ruby-9 rounded-lg hover:bg-n-ruby-10"
                        @click="removeBanner"
                      >
                        <div class="i-lucide-trash-2 size-4 text-white" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Status Toggle -->
              <div class="flex items-center justify-between py-2">
                <div>
                  <p class="text-sm font-medium text-n-slate-12">
                    {{ $t('SHOP.SETTINGS.STATUS.TITLE') }}
                  </p>
                  <p class="text-sm text-n-slate-11">
                    {{ $t('SHOP.SETTINGS.STATUS.DESCRIPTION') }}
                  </p>
                </div>
                <label class="relative inline-flex items-center cursor-pointer">
                  <input
                    v-model="settings.enabled"
                    type="checkbox"
                    class="sr-only peer"
                  />
                  <div
                    class="w-11 h-6 bg-n-slate-6 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-n-brand"
                  />
                </label>
              </div>
            </div>
          </SettingsSection>

          <SettingsSection
            :title="$t('SHOP.SETTINGS.CONTACT.TITLE')"
            sub-title=""
          >
            <div class="flex flex-col gap-4">
              <div class="grid grid-cols-2 gap-4">
                <label class="block">
                  <span
                    class="text-sm font-medium text-n-slate-12 mb-1.5 block"
                  >
                    {{ $t('SHOP.SETTINGS.CONTACT.WHATSAPP_LABEL') }}
                  </span>
                  <input
                    v-model="settings.whatsapp_number"
                    type="text"
                    class="w-full"
                    :placeholder="
                      $t('SHOP.SETTINGS.CONTACT.WHATSAPP_PLACEHOLDER')
                    "
                  />
                </label>
                <label class="block">
                  <span
                    class="text-sm font-medium text-n-slate-12 mb-1.5 block"
                  >
                    {{ $t('SHOP.SETTINGS.CONTACT.EMAIL_LABEL') }}
                  </span>
                  <input
                    v-model="settings.contact_email"
                    type="email"
                    class="w-full"
                    :placeholder="$t('SHOP.SETTINGS.CONTACT.EMAIL_PLACEHOLDER')"
                  />
                </label>
              </div>

              <label class="block">
                <span class="text-sm font-medium text-n-slate-12 mb-1.5 block">
                  {{ $t('SHOP.SETTINGS.CONTACT.HOURS_LABEL') }}
                </span>
                <input
                  v-model="settings.business_hours"
                  type="text"
                  class="w-full"
                  :placeholder="$t('SHOP.SETTINGS.CONTACT.HOURS_PLACEHOLDER')"
                />
              </label>

              <label class="block">
                <span class="text-sm font-medium text-n-slate-12 mb-1.5 block">
                  {{ $t('SHOP.SETTINGS.CONTACT.MESSAGE_LABEL') }}
                </span>
                <textarea
                  v-model="settings.order_message_template"
                  rows="3"
                  class="w-full"
                  :placeholder="$t('SHOP.SETTINGS.CONTACT.MESSAGE_PLACEHOLDER')"
                />
                <p class="text-sm text-n-slate-11 mt-1">
                  {{ $t('SHOP.SETTINGS.CONTACT.MESSAGE_HELP') }}
                </p>
              </label>
            </div>
          </SettingsSection>

          <SettingsSection
            :title="$t('SHOP.SETTINGS.MINIMUM_ORDER.TITLE')"
            sub-title=""
          >
            <div class="grid grid-cols-2 gap-4">
              <label class="block">
                <span class="text-sm font-medium text-n-slate-12 mb-1.5 block">
                  {{ $t('SHOP.SETTINGS.MINIMUM_ORDER.VALUE_LABEL') }}
                </span>
                <input
                  v-model="settings.minimum_order_value"
                  type="number"
                  step="0.01"
                  class="w-full"
                  :placeholder="
                    $t('SHOP.SETTINGS.MINIMUM_ORDER.VALUE_PLACEHOLDER')
                  "
                />
                <p class="text-sm text-n-slate-11 mt-1">
                  {{ $t('SHOP.SETTINGS.MINIMUM_ORDER.VALUE_HELP') }}
                </p>
              </label>
              <label class="block">
                <span class="text-sm font-medium text-n-slate-12 mb-1.5 block">
                  {{ $t('SHOP.SETTINGS.MINIMUM_ORDER.MESSAGE_LABEL') }}
                </span>
                <input
                  v-model="settings.minimum_order_message"
                  type="text"
                  class="w-full"
                  :placeholder="
                    $t('SHOP.SETTINGS.MINIMUM_ORDER.MESSAGE_PLACEHOLDER')
                  "
                />
              </label>
            </div>
          </SettingsSection>

          <SettingsSection
            :title="$t('SHOP.SETTINGS.EXTRA_INFO.TITLE')"
            sub-title=""
            :show-border="false"
          >
            <div class="flex flex-col gap-4">
              <label class="block">
                <span class="text-sm font-medium text-n-slate-12 mb-1.5 block">
                  {{ $t('SHOP.SETTINGS.EXTRA_INFO.ADDRESS_LABEL') }}
                </span>
                <textarea
                  v-model="settings.address"
                  rows="2"
                  class="w-full"
                  :placeholder="
                    $t('SHOP.SETTINGS.EXTRA_INFO.ADDRESS_PLACEHOLDER')
                  "
                />
              </label>

              <label class="block">
                <span class="text-sm font-medium text-n-slate-12 mb-1.5 block">
                  {{ $t('SHOP.SETTINGS.EXTRA_INFO.FOOTER_LABEL') }}
                </span>
                <textarea
                  v-model="settings.footer_text"
                  rows="2"
                  class="w-full"
                  :placeholder="
                    $t('SHOP.SETTINGS.EXTRA_INFO.FOOTER_PLACEHOLDER')
                  "
                />
                <p class="text-sm text-n-slate-11 mt-1">
                  {{ $t('SHOP.SETTINGS.EXTRA_INFO.FOOTER_HELP') }}
                </p>
              </label>
            </div>
          </SettingsSection>
        </template>

        <!-- Tab: Display -->
        <template v-if="selectedTabKey === 'display'">
          <SettingsSection
            :title="$t('SHOP.SETTINGS.DISPLAY.TITLE')"
            sub-title=""
          >
            <div class="flex flex-col gap-4">
              <!-- Toggles -->
              <div class="flex items-center justify-between py-2">
                <div>
                  <p class="text-sm font-medium text-n-slate-12">
                    {{ $t('SHOP.SETTINGS.DISPLAY.SHOW_PRICES') }}
                  </p>
                  <p class="text-sm text-n-slate-11">
                    {{ $t('SHOP.SETTINGS.DISPLAY.SHOW_PRICES_HELP') }}
                  </p>
                </div>
                <label class="relative inline-flex items-center cursor-pointer">
                  <input
                    v-model="settings.show_prices"
                    type="checkbox"
                    class="sr-only peer"
                  />
                  <div
                    class="w-11 h-6 bg-n-slate-6 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-n-brand"
                  />
                </label>
              </div>

              <div class="flex items-center justify-between py-2">
                <div>
                  <p class="text-sm font-medium text-n-slate-12">
                    {{ $t('SHOP.SETTINGS.DISPLAY.SHOW_OUT_OF_STOCK') }}
                  </p>
                  <p class="text-sm text-n-slate-11">
                    {{ $t('SHOP.SETTINGS.DISPLAY.SHOW_OUT_OF_STOCK_HELP') }}
                  </p>
                </div>
                <label class="relative inline-flex items-center cursor-pointer">
                  <input
                    v-model="settings.show_out_of_stock"
                    type="checkbox"
                    class="sr-only peer"
                  />
                  <div
                    class="w-11 h-6 bg-n-slate-6 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-n-brand"
                  />
                </label>
              </div>

              <div class="flex items-center justify-between py-2">
                <div>
                  <p class="text-sm font-medium text-n-slate-12">
                    {{ $t('SHOP.SETTINGS.DISPLAY.SHOW_CATEGORIES') }}
                  </p>
                  <p class="text-sm text-n-slate-11">
                    {{ $t('SHOP.SETTINGS.DISPLAY.SHOW_CATEGORIES_HELP') }}
                  </p>
                </div>
                <label class="relative inline-flex items-center cursor-pointer">
                  <input
                    v-model="settings.show_categories_bar"
                    type="checkbox"
                    class="sr-only peer"
                  />
                  <div
                    class="w-11 h-6 bg-n-slate-6 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-n-brand"
                  />
                </label>
              </div>

              <!-- Selects -->
              <div class="grid grid-cols-2 gap-4 pt-4 border-t border-n-weak">
                <label class="block">
                  <span
                    class="text-sm font-medium text-n-slate-12 mb-1.5 block"
                  >
                    {{ $t('SHOP.SETTINGS.DISPLAY.SORT_LABEL') }}
                  </span>
                  <select v-model="settings.default_sort" class="w-full">
                    <option
                      v-for="option in sortOptions"
                      :key="option.value"
                      :value="option.value"
                    >
                      {{ option.label }}
                    </option>
                  </select>
                </label>

                <label class="block">
                  <span
                    class="text-sm font-medium text-n-slate-12 mb-1.5 block"
                  >
                    {{ $t('SHOP.SETTINGS.DISPLAY.PRODUCTS_PER_PAGE_LABEL') }}
                  </span>
                  <select v-model="settings.products_per_page" class="w-full">
                    <option
                      v-for="num in productsPerPageOptions"
                      :key="num"
                      :value="num"
                    >
                      {{
                        $t('SHOP.SETTINGS.DISPLAY.PRODUCTS_COUNT', {
                          count: num,
                        })
                      }}
                    </option>
                  </select>
                </label>
              </div>
            </div>
          </SettingsSection>

          <SettingsSection
            :title="$t('SHOP.SETTINGS.BADGE.TITLE')"
            sub-title=""
            :show-border="false"
          >
            <div class="flex flex-col gap-4">
              <div class="flex items-center justify-between py-2">
                <p class="text-sm font-medium text-n-slate-12">
                  {{ $t('SHOP.SETTINGS.BADGE.TITLE') }}
                </p>
                <label class="relative inline-flex items-center cursor-pointer">
                  <input
                    v-model="settings.show_featured_badge"
                    type="checkbox"
                    class="sr-only peer"
                  />
                  <div
                    class="w-11 h-6 bg-n-slate-6 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-n-brand"
                  />
                </label>
              </div>

              <div
                v-if="settings.show_featured_badge"
                class="flex flex-col gap-4"
              >
                <label class="block">
                  <span
                    class="text-sm font-medium text-n-slate-12 mb-1.5 block"
                  >
                    {{ $t('SHOP.SETTINGS.BADGE.TEXT_LABEL') }}
                  </span>
                  <input
                    v-model="settings.featured_badge_text"
                    type="text"
                    class="w-full"
                    :placeholder="$t('SHOP.SETTINGS.BADGE.TEXT_PLACEHOLDER')"
                  />
                </label>

                <div class="flex items-center gap-3">
                  <span class="text-sm text-n-slate-11">
                    {{ $t('SHOP.SETTINGS.BADGE.PREVIEW') }}
                  </span>
                  <span
                    class="px-2.5 py-1 text-xs font-semibold text-white rounded-full"
                    :style="{ backgroundColor: settings.primary_color }"
                  >
                    {{ settings.featured_badge_text || 'Destaque' }}
                  </span>
                </div>
              </div>
            </div>
          </SettingsSection>
        </template>

        <!-- Tab: Appearance -->
        <template v-if="selectedTabKey === 'appearance'">
          <SettingsSection
            :title="$t('SHOP.SETTINGS.APPEARANCE.TITLE')"
            sub-title=""
          >
            <div class="flex flex-col gap-4">
              <div class="grid grid-cols-2 gap-4">
                <label class="block">
                  <span
                    class="text-sm font-medium text-n-slate-12 mb-1.5 block"
                  >
                    {{ $t('SHOP.SETTINGS.APPEARANCE.PRIMARY_COLOR') }}
                  </span>
                  <div class="flex items-center gap-2">
                    <input
                      v-model="settings.primary_color"
                      type="color"
                      class="w-10 h-10 rounded-lg cursor-pointer border border-n-weak"
                    />
                    <input
                      v-model="settings.primary_color"
                      type="text"
                      class="flex-1"
                    />
                  </div>
                </label>

                <label class="block">
                  <span
                    class="text-sm font-medium text-n-slate-12 mb-1.5 block"
                  >
                    {{ $t('SHOP.SETTINGS.APPEARANCE.SECONDARY_COLOR') }}
                  </span>
                  <div class="flex items-center gap-2">
                    <input
                      v-model="settings.secondary_color"
                      type="color"
                      class="w-10 h-10 rounded-lg cursor-pointer border border-n-weak"
                    />
                    <input
                      v-model="settings.secondary_color"
                      type="text"
                      class="flex-1"
                    />
                  </div>
                </label>

                <label class="block">
                  <span
                    class="text-sm font-medium text-n-slate-12 mb-1.5 block"
                  >
                    {{ $t('SHOP.SETTINGS.APPEARANCE.BACKGROUND_COLOR') }}
                  </span>
                  <div class="flex items-center gap-2">
                    <input
                      v-model="settings.background_color"
                      type="color"
                      class="w-10 h-10 rounded-lg cursor-pointer border border-n-weak"
                    />
                    <input
                      v-model="settings.background_color"
                      type="text"
                      class="flex-1"
                    />
                  </div>
                </label>

                <label class="block">
                  <span
                    class="text-sm font-medium text-n-slate-12 mb-1.5 block"
                  >
                    {{ $t('SHOP.SETTINGS.APPEARANCE.TEXT_COLOR') }}
                  </span>
                  <div class="flex items-center gap-2">
                    <input
                      v-model="settings.text_color"
                      type="color"
                      class="w-10 h-10 rounded-lg cursor-pointer border border-n-weak"
                    />
                    <input
                      v-model="settings.text_color"
                      type="text"
                      class="flex-1"
                    />
                  </div>
                </label>
              </div>

              <!-- Preview das cores -->
              <div
                class="p-4 rounded-lg border border-n-weak"
                :style="{
                  backgroundColor: settings.background_color,
                  color: settings.text_color,
                }"
              >
                <p class="text-sm font-medium mb-1">
                  {{ $t('SHOP.SETTINGS.APPEARANCE.PREVIEW') }}
                </p>
                <p class="text-xs" :style="{ color: settings.secondary_color }">
                  {{ $t('SHOP.SETTINGS.APPEARANCE.PREVIEW_SECONDARY') }}
                </p>
                <button
                  class="mt-2 px-3 py-1.5 rounded-lg text-white text-xs font-medium"
                  :style="{ backgroundColor: settings.primary_color }"
                >
                  {{ $t('SHOP.SETTINGS.APPEARANCE.PREVIEW_BUTTON') }}
                </button>
              </div>
            </div>
          </SettingsSection>

          <SettingsSection
            :title="$t('SHOP.SETTINGS.LAYOUT.TITLE')"
            sub-title=""
            :show-border="false"
          >
            <div class="flex flex-col gap-4">
              <div class="grid grid-cols-3 gap-4">
                <label class="block">
                  <span
                    class="text-sm font-medium text-n-slate-12 mb-1.5 block"
                  >
                    {{ $t('SHOP.SETTINGS.APPEARANCE.HEADER_LABEL') }}
                  </span>
                  <select v-model="settings.header_style" class="w-full">
                    <option
                      v-for="style in headerStyles"
                      :key="style.value"
                      :value="style.value"
                    >
                      {{ style.label }}
                    </option>
                  </select>
                </label>

                <label class="block">
                  <span
                    class="text-sm font-medium text-n-slate-12 mb-1.5 block"
                  >
                    {{ $t('SHOP.SETTINGS.LAYOUT.PRODUCTS_PER_ROW') }}
                  </span>
                  <select v-model="settings.products_per_row" class="w-full">
                    <option
                      v-for="option in productsPerRowOptions"
                      :key="option.value"
                      :value="option.value"
                    >
                      {{ option.label }}
                    </option>
                  </select>
                </label>

                <label class="block">
                  <span
                    class="text-sm font-medium text-n-slate-12 mb-1.5 block"
                  >
                    {{ $t('SHOP.SETTINGS.LAYOUT.CARD_STYLE') }}
                  </span>
                  <select v-model="settings.card_style" class="w-full">
                    <option
                      v-for="style in cardStyles"
                      :key="style.value"
                      :value="style.value"
                    >
                      {{ style.label }}
                    </option>
                  </select>
                </label>
              </div>

              <!-- Preview do Layout -->
              <div class="pt-4">
                <p class="text-xs font-medium text-n-slate-11 mb-2">
                  {{ $t('SHOP.SETTINGS.LAYOUT.PREVIEW') }}
                </p>
                <div
                  class="grid gap-2 p-3 bg-n-alpha-2 rounded-lg"
                  :class="{
                    'grid-cols-2': settings.products_per_row === 2,
                    'grid-cols-3': settings.products_per_row === 3,
                    'grid-cols-4': settings.products_per_row === 4,
                  }"
                >
                  <div
                    v-for="n in settings.products_per_row"
                    :key="n"
                    class="aspect-square bg-white dark:bg-n-solid-3 rounded-lg"
                    :class="{
                      'shadow-md': settings.card_style === 'shadow',
                      'border-2 border-n-weak':
                        settings.card_style === 'border',
                    }"
                  />
                </div>
              </div>
            </div>
          </SettingsSection>
        </template>

        <!-- Tab: Delivery -->
        <template v-if="selectedTabKey === 'delivery'">
          <SettingsSection
            :title="$t('SHOP.SETTINGS.DELIVERY.TITLE')"
            sub-title=""
            :show-border="false"
          >
            <div class="flex flex-col gap-4">
              <label class="block">
                <span class="text-sm font-medium text-n-slate-12 mb-1.5 block">
                  {{ $t('SHOP.SETTINGS.DELIVERY.INFO_LABEL') }}
                </span>
                <textarea
                  v-model="settings.delivery_info"
                  rows="3"
                  class="w-full"
                  :placeholder="$t('SHOP.SETTINGS.DELIVERY.INFO_PLACEHOLDER')"
                />
              </label>

              <label class="block">
                <span class="text-sm font-medium text-n-slate-12 mb-1.5 block">
                  {{ $t('SHOP.SETTINGS.DELIVERY.AREAS_LABEL') }}
                </span>
                <textarea
                  v-model="settings.delivery_areas"
                  rows="3"
                  class="w-full"
                  :placeholder="$t('SHOP.SETTINGS.DELIVERY.AREAS_PLACEHOLDER')"
                />
                <p class="text-sm text-n-slate-11 mt-1">
                  {{ $t('SHOP.SETTINGS.DELIVERY.AREAS_HELP') }}
                </p>
              </label>

              <label class="block">
                <span class="text-sm font-medium text-n-slate-12 mb-1.5 block">
                  {{ $t('SHOP.SETTINGS.DELIVERY.PICKUP_LABEL') }}
                </span>
                <textarea
                  v-model="settings.pickup_info"
                  rows="3"
                  class="w-full"
                  :placeholder="$t('SHOP.SETTINGS.DELIVERY.PICKUP_PLACEHOLDER')"
                />
              </label>
            </div>
          </SettingsSection>
        </template>
      </section>
    </div>

    <!-- Modal de Preview Fullscreen -->
    <Teleport to="body">
      <div
        v-if="showPreviewModal"
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/70"
        @click.self="showPreviewModal = false"
      >
        <div
          class="bg-n-solid-1 rounded-2xl shadow-2xl overflow-hidden flex flex-col"
          :class="
            previewMode === 'desktop'
              ? 'w-[95vw] h-[90vh]'
              : 'max-w-full max-h-[90vh]'
          "
        >
          <!-- Header do Modal -->
          <div
            class="flex items-center justify-between px-4 py-3 border-b border-n-weak"
          >
            <h3 class="text-sm font-semibold text-n-slate-12">
              {{ $t('SHOP.SETTINGS.PREVIEW.TITLE') }}
            </h3>

            <div class="flex items-center gap-2">
              <!-- Device toggles -->
              <div class="flex items-center gap-1 p-1 bg-n-alpha-2 rounded-lg">
                <button
                  class="p-2 rounded-md transition-colors"
                  :class="
                    previewMode === 'mobile'
                      ? 'bg-white dark:bg-n-solid-3 shadow-sm'
                      : 'hover:bg-n-alpha-3'
                  "
                  @click="previewMode = 'mobile'"
                >
                  <div
                    class="i-lucide-smartphone size-4"
                    :class="
                      previewMode === 'mobile'
                        ? 'text-n-brand'
                        : 'text-n-slate-11'
                    "
                  />
                </button>
                <button
                  class="p-2 rounded-md transition-colors"
                  :class="
                    previewMode === 'desktop'
                      ? 'bg-white dark:bg-n-solid-3 shadow-sm'
                      : 'hover:bg-n-alpha-3'
                  "
                  @click="previewMode = 'desktop'"
                >
                  <div
                    class="i-lucide-monitor size-4"
                    :class="
                      previewMode === 'desktop'
                        ? 'text-n-brand'
                        : 'text-n-slate-11'
                    "
                  />
                </button>
              </div>

              <button
                class="p-2 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2 rounded-lg"
                @click="showPreviewModal = false"
              >
                <div class="i-lucide-x size-4" />
              </button>
            </div>
          </div>

          <!-- Preview Area -->
          <div
            class="flex-1 flex items-center justify-center p-4 overflow-auto bg-n-alpha-2"
          >
            <div
              class="bg-white rounded-lg shadow-lg overflow-hidden transition-all duration-300"
              :class="previewContainerClass"
            >
              <iframe
                ref="previewIframe"
                :key="previewKey"
                :src="previewIframeSrc"
                class="w-full h-full border-0"
                :title="$t('SHOP.SETTINGS.PREVIEW.TITLE')"
                @load="onPreviewLoad"
              />
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
