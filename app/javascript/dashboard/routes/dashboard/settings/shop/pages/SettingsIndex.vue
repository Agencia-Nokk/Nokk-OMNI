<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import ShopAPI from 'dashboard/api/shop';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Textarea from 'dashboard/components-next/textarea/TextArea.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const { t } = useI18n();

const isLoading = ref(true);
const isSaving = ref(false);
const settings = ref({
  // Informações Básicas
  name: '',
  description: '',
  // Contato e Pedidos
  whatsapp_number: '',
  order_message_template: '',
  contact_email: '',
  business_hours: '',
  // Configurações de Exibição
  enabled: true,
  show_out_of_stock: true,
  show_prices: true,
  default_sort: 'newest',
  products_per_page: 12,
  // Pedido Mínimo
  minimum_order_value: null,
  minimum_order_message: '',
  // Informações de Entrega
  delivery_info: '',
  delivery_areas: '',
  pickup_info: '',
  // Aparência/Tema
  primary_color: '#1F93FF',
  header_style: 'minimal',
  show_categories_bar: true,
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

const productsPerPageOptions = [8, 12, 16, 24, 32, 48];

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

    // Adiciona todos os campos
    Object.keys(settings.value).forEach(key => {
      if (settings.value[key] !== null && settings.value[key] !== undefined) {
        formData.append(`setting[${key}]`, settings.value[key]);
      }
    });

    // Adiciona arquivos se selecionados
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

onMounted(() => {
  fetchSettings();
});
</script>

<template>
  <div class="flex flex-col h-full">
    <div
      class="flex items-center justify-between p-4 border-b border-slate-75 dark:border-slate-800"
    >
      <div>
        <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-25">
          {{ $t('SHOP.SETTINGS.TITLE') }}
        </h2>
        <p class="text-sm text-slate-600 dark:text-slate-400">
          {{ $t('SHOP.SETTINGS.DESCRIPTION') }}
        </p>
      </div>
      <Button
        :label="$t('SHOP.SETTINGS.SAVE')"
        icon="i-lucide-save"
        :is-loading="isSaving"
        @click="saveSettings"
      />
    </div>

    <div v-if="isLoading" class="flex items-center justify-center h-full">
      <Spinner />
    </div>

    <div v-else class="flex-1 overflow-y-auto p-4 space-y-8">
      <!-- URL Pública -->
      <div class="bg-woot-50 dark:bg-woot-900/20 rounded-xl p-4">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-woot-700 dark:text-woot-300">
              {{ $t('SHOP.SETTINGS.STORE_URL') }}
            </h3>
            <p class="text-sm text-woot-600 dark:text-woot-400 mt-1 font-mono">
              {{ publicUrl }}
            </p>
          </div>
          <div class="flex items-center gap-2">
            <Button
              variant="hollow"
              size="sm"
              icon="i-lucide-copy"
              @click="copyPublicUrl"
            />
            <a
              :href="publicUrl"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-woot-600 hover:text-woot-700 bg-white dark:bg-slate-800 rounded-lg border border-woot-200 dark:border-woot-700"
            >
              <div class="i-lucide-external-link size-4" />
              {{ $t('SHOP.SETTINGS.OPEN') }}
            </a>
          </div>
        </div>
      </div>

      <!-- Status da Loja -->
      <div
        class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-6"
      >
        <div class="flex items-center justify-between">
          <div>
            <h3
              class="text-lg font-semibold text-slate-900 dark:text-slate-100"
            >
              {{ $t('SHOP.SETTINGS.STATUS.TITLE') }}
            </h3>
            <p class="text-sm text-slate-600 dark:text-slate-400 mt-1">
              {{ $t('SHOP.SETTINGS.STATUS.DESCRIPTION') }}
            </p>
          </div>
          <div class="flex items-center gap-3">
            <span
              class="px-3 py-1 text-sm font-medium rounded-full"
              :class="
                settings.enabled
                  ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                  : 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400'
              "
            >
              {{
                settings.enabled
                  ? $t('SHOP.SETTINGS.STATUS.ONLINE')
                  : $t('SHOP.SETTINGS.STATUS.OFFLINE')
              }}
            </span>
            <Switch v-model="settings.enabled" />
          </div>
        </div>
      </div>

      <!-- 1. Informações Básicas -->
      <section
        class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-6 space-y-6"
      >
        <h3
          class="text-lg font-semibold text-slate-900 dark:text-slate-100 flex items-center gap-2"
        >
          <div class="i-lucide-store size-5" />
          {{ $t('SHOP.SETTINGS.BASIC_INFO.TITLE') }}
        </h3>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Input
            v-model="settings.name"
            :label="$t('SHOP.SETTINGS.BASIC_INFO.NAME_LABEL')"
            :placeholder="$t('SHOP.SETTINGS.BASIC_INFO.NAME_PLACEHOLDER')"
          />
          <div />
        </div>

        <Textarea
          v-model="settings.description"
          :label="$t('SHOP.SETTINGS.BASIC_INFO.DESCRIPTION_LABEL')"
          :placeholder="$t('SHOP.SETTINGS.BASIC_INFO.DESCRIPTION_PLACEHOLDER')"
          auto-height
          min-height="5rem"
        />

        <!-- Logo -->
        <div>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
          >
            {{ $t('SHOP.SETTINGS.BASIC_INFO.LOGO_LABEL') }}
          </label>
          <div class="flex items-center gap-4">
            <div
              class="w-24 h-24 rounded-xl bg-slate-100 dark:bg-slate-700 flex items-center justify-center overflow-hidden border-2 border-dashed border-slate-300 dark:border-slate-600"
            >
              <img
                v-if="logoUrl"
                :src="logoUrl"
                alt="Logo"
                class="w-full h-full object-cover"
              />
              <div v-else class="i-lucide-image size-8 text-slate-400" />
            </div>
            <div class="space-y-2">
              <label
                class="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-woot-600 bg-woot-50 hover:bg-woot-100 dark:bg-woot-900/20 dark:hover:bg-woot-900/30 rounded-lg cursor-pointer transition-colors"
              >
                <div class="i-lucide-upload size-4" />
                {{ $t('SHOP.SETTINGS.BASIC_INFO.LOGO_CHOOSE') }}
                <input
                  type="file"
                  accept="image/*"
                  class="hidden"
                  @change="onLogoChange"
                />
              </label>
              <button
                v-if="logoUrl"
                class="block text-sm text-red-600 hover:text-red-700"
                @click="removeLogo"
              >
                {{ $t('SHOP.SETTINGS.BASIC_INFO.LOGO_REMOVE') }}
              </button>
            </div>
          </div>
        </div>

        <!-- Banner -->
        <div>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
          >
            {{ $t('SHOP.SETTINGS.BASIC_INFO.BANNER_LABEL') }}
          </label>
          <div
            class="w-full h-32 rounded-xl bg-slate-100 dark:bg-slate-700 flex items-center justify-center overflow-hidden border-2 border-dashed border-slate-300 dark:border-slate-600 relative"
          >
            <img
              v-if="bannerUrl"
              :src="bannerUrl"
              alt="Banner"
              class="w-full h-full object-cover"
            />
            <div v-else class="i-lucide-image size-10 text-slate-400" />
            <div
              class="absolute inset-0 flex items-center justify-center gap-2 bg-black/50 opacity-0 hover:opacity-100 transition-opacity"
            >
              <label
                class="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-woot-500 hover:bg-woot-600 rounded-lg cursor-pointer transition-colors"
              >
                <div class="i-lucide-upload size-4" />
                {{ $t('SHOP.SETTINGS.BASIC_INFO.BANNER_CHANGE') }}
                <input
                  type="file"
                  accept="image/*"
                  class="hidden"
                  @change="onBannerChange"
                />
              </label>
              <button
                v-if="bannerUrl"
                class="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-red-500 hover:bg-red-600 rounded-lg transition-colors"
                @click="removeBanner"
              >
                <div class="i-lucide-trash-2 size-4" />
                {{ $t('SHOP.SETTINGS.BASIC_INFO.BANNER_REMOVE') }}
              </button>
            </div>
          </div>
        </div>
      </section>

      <!-- 2. Contato e Pedidos -->
      <section
        class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-6 space-y-6"
      >
        <h3
          class="text-lg font-semibold text-slate-900 dark:text-slate-100 flex items-center gap-2"
        >
          <div class="i-lucide-message-circle size-5" />
          {{ $t('SHOP.SETTINGS.CONTACT.TITLE') }}
        </h3>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Input
            v-model="settings.whatsapp_number"
            :label="$t('SHOP.SETTINGS.CONTACT.WHATSAPP_LABEL')"
            :placeholder="$t('SHOP.SETTINGS.CONTACT.WHATSAPP_PLACEHOLDER')"
            :message="$t('SHOP.SETTINGS.CONTACT.WHATSAPP_HELP')"
          />
          <Input
            v-model="settings.contact_email"
            :label="$t('SHOP.SETTINGS.CONTACT.EMAIL_LABEL')"
            type="email"
            :placeholder="$t('SHOP.SETTINGS.CONTACT.EMAIL_PLACEHOLDER')"
          />
        </div>

        <Input
          v-model="settings.business_hours"
          :label="$t('SHOP.SETTINGS.CONTACT.HOURS_LABEL')"
          :placeholder="$t('SHOP.SETTINGS.CONTACT.HOURS_PLACEHOLDER')"
        />

        <Textarea
          v-model="settings.order_message_template"
          :label="$t('SHOP.SETTINGS.CONTACT.MESSAGE_LABEL')"
          :placeholder="$t('SHOP.SETTINGS.CONTACT.MESSAGE_PLACEHOLDER')"
          :message="$t('SHOP.SETTINGS.CONTACT.MESSAGE_HELP')"
          auto-height
          min-height="5rem"
        />
      </section>

      <!-- 3. Configurações de Exibição -->
      <section
        class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-6 space-y-6"
      >
        <h3
          class="text-lg font-semibold text-slate-900 dark:text-slate-100 flex items-center gap-2"
        >
          <div class="i-lucide-layout-grid size-5" />
          {{ $t('SHOP.SETTINGS.DISPLAY.TITLE') }}
        </h3>

        <div class="space-y-4">
          <div class="flex items-center justify-between py-2">
            <div>
              <p class="text-sm font-medium text-slate-900 dark:text-slate-100">
                {{ $t('SHOP.SETTINGS.DISPLAY.SHOW_OUT_OF_STOCK') }}
              </p>
              <p class="text-sm text-slate-500 dark:text-slate-400">
                {{ $t('SHOP.SETTINGS.DISPLAY.SHOW_OUT_OF_STOCK_HELP') }}
              </p>
            </div>
            <Switch v-model="settings.show_out_of_stock" />
          </div>

          <div
            class="flex items-center justify-between py-2 border-t border-slate-100 dark:border-slate-700"
          >
            <div>
              <p class="text-sm font-medium text-slate-900 dark:text-slate-100">
                {{ $t('SHOP.SETTINGS.DISPLAY.SHOW_PRICES') }}
              </p>
              <p class="text-sm text-slate-500 dark:text-slate-400">
                {{ $t('SHOP.SETTINGS.DISPLAY.SHOW_PRICES_HELP') }}
              </p>
            </div>
            <Switch v-model="settings.show_prices" />
          </div>

          <div
            class="flex items-center justify-between py-2 border-t border-slate-100 dark:border-slate-700"
          >
            <div>
              <p class="text-sm font-medium text-slate-900 dark:text-slate-100">
                {{ $t('SHOP.SETTINGS.DISPLAY.SHOW_CATEGORIES') }}
              </p>
              <p class="text-sm text-slate-500 dark:text-slate-400">
                {{ $t('SHOP.SETTINGS.DISPLAY.SHOW_CATEGORIES_HELP') }}
              </p>
            </div>
            <Switch v-model="settings.show_categories_bar" />
          </div>
        </div>

        <div
          class="grid grid-cols-1 md:grid-cols-2 gap-6 pt-4 border-t border-slate-100 dark:border-slate-700"
        >
          <div>
            <label
              class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
            >
              {{ $t('SHOP.SETTINGS.DISPLAY.SORT_LABEL') }}
            </label>
            <select
              v-model="settings.default_sort"
              class="w-full px-3 py-2 text-sm border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
            >
              <option
                v-for="option in sortOptions"
                :key="option.value"
                :value="option.value"
              >
                {{ option.label }}
              </option>
            </select>
          </div>

          <div>
            <label
              class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
            >
              {{ $t('SHOP.SETTINGS.DISPLAY.PRODUCTS_PER_PAGE_LABEL') }}
            </label>
            <select
              v-model="settings.products_per_page"
              class="w-full px-3 py-2 text-sm border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
            >
              <option
                v-for="num in productsPerPageOptions"
                :key="num"
                :value="num"
              >
                {{ $t('SHOP.SETTINGS.DISPLAY.PRODUCTS_COUNT', { count: num }) }}
              </option>
            </select>
          </div>
        </div>
      </section>

      <!-- 4. Pedido Mínimo -->
      <section
        class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-6 space-y-6"
      >
        <h3
          class="text-lg font-semibold text-slate-900 dark:text-slate-100 flex items-center gap-2"
        >
          <div class="i-lucide-shopping-cart size-5" />
          {{ $t('SHOP.SETTINGS.MINIMUM_ORDER.TITLE') }}
        </h3>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Input
            v-model="settings.minimum_order_value"
            :label="$t('SHOP.SETTINGS.MINIMUM_ORDER.VALUE_LABEL')"
            type="number"
            :placeholder="$t('SHOP.SETTINGS.MINIMUM_ORDER.VALUE_PLACEHOLDER')"
            step="0.01"
            :message="$t('SHOP.SETTINGS.MINIMUM_ORDER.VALUE_HELP')"
          />
          <Input
            v-model="settings.minimum_order_message"
            :label="$t('SHOP.SETTINGS.MINIMUM_ORDER.MESSAGE_LABEL')"
            :placeholder="$t('SHOP.SETTINGS.MINIMUM_ORDER.MESSAGE_PLACEHOLDER')"
          />
        </div>
      </section>

      <!-- 5. Informações de Entrega -->
      <section
        class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-6 space-y-6"
      >
        <h3
          class="text-lg font-semibold text-slate-900 dark:text-slate-100 flex items-center gap-2"
        >
          <div class="i-lucide-truck size-5" />
          {{ $t('SHOP.SETTINGS.DELIVERY.TITLE') }}
        </h3>

        <Textarea
          v-model="settings.delivery_info"
          :label="$t('SHOP.SETTINGS.DELIVERY.INFO_LABEL')"
          :placeholder="$t('SHOP.SETTINGS.DELIVERY.INFO_PLACEHOLDER')"
          auto-height
          min-height="4rem"
        />

        <Textarea
          v-model="settings.delivery_areas"
          :label="$t('SHOP.SETTINGS.DELIVERY.AREAS_LABEL')"
          :placeholder="$t('SHOP.SETTINGS.DELIVERY.AREAS_PLACEHOLDER')"
          :message="$t('SHOP.SETTINGS.DELIVERY.AREAS_HELP')"
          auto-height
          min-height="4rem"
        />

        <Textarea
          v-model="settings.pickup_info"
          :label="$t('SHOP.SETTINGS.DELIVERY.PICKUP_LABEL')"
          :placeholder="$t('SHOP.SETTINGS.DELIVERY.PICKUP_PLACEHOLDER')"
          auto-height
          min-height="4rem"
        />
      </section>

      <!-- 6. Aparência/Tema -->
      <section
        class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-6 space-y-6"
      >
        <h3
          class="text-lg font-semibold text-slate-900 dark:text-slate-100 flex items-center gap-2"
        >
          <div class="i-lucide-palette size-5" />
          {{ $t('SHOP.SETTINGS.APPEARANCE.TITLE') }}
        </h3>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label
              class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
            >
              {{ $t('SHOP.SETTINGS.APPEARANCE.COLOR_LABEL') }}
            </label>
            <div class="flex items-center gap-3">
              <input
                v-model="settings.primary_color"
                type="color"
                class="w-12 h-12 rounded-lg cursor-pointer border border-slate-300 dark:border-slate-600"
              />
              <Input
                v-model="settings.primary_color"
                class="flex-1"
                :placeholder="$t('SHOP.SETTINGS.APPEARANCE.COLOR_PLACEHOLDER')"
              />
            </div>
          </div>

          <div>
            <label
              class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
            >
              {{ $t('SHOP.SETTINGS.APPEARANCE.HEADER_LABEL') }}
            </label>
            <select
              v-model="settings.header_style"
              class="w-full px-3 py-2 text-sm border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100"
            >
              <option
                v-for="style in headerStyles"
                :key="style.value"
                :value="style.value"
              >
                {{ style.label }}
              </option>
            </select>
          </div>
        </div>
      </section>

      <!-- Botão Salvar no final -->
      <div class="flex justify-end pb-8">
        <Button
          :label="$t('SHOP.SETTINGS.SAVE')"
          icon="i-lucide-save"
          :is-loading="isSaving"
          @click="saveSettings"
        />
      </div>
    </div>
  </div>
</template>
