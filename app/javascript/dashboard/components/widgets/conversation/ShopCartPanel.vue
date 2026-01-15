<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters } from 'dashboard/composables/store';
import ShopAPI from 'dashboard/api/shop';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();
const getters = useStoreGetters();

const cart = ref(null);
const loading = ref(true);
const error = ref('');
const lastMessageCount = ref(0);

// Get current conversation from store
const currentChat = computed(() => {
  return getters.getConversationById.value(props.conversationId);
});

// Watch for new messages in the conversation
const messageCount = computed(() => {
  return currentChat.value?.messages?.length || 0;
});

const hasItems = computed(() => cart.value?.items?.length > 0);

const itemCountLabel = computed(() => {
  const count = cart.value?.total_items || 0;
  const itemWord = count === 1 ? t('SHOP_CART.ITEM') : t('SHOP_CART.ITEMS');
  return `${count} ${itemWord}`;
});

const formatPrice = price => {
  if (!price) return 'R$ 0,00';
  return `R$ ${Number(price).toFixed(2).replace('.', ',')}`;
};

const fetchCart = async () => {
  if (!props.conversationId) return;

  try {
    loading.value = true;
    error.value = '';
    const response = await ShopAPI.getCartByConversation(props.conversationId);
    cart.value = response.data;
  } catch (err) {
    if (err.response?.status !== 404) {
      error.value = t('SHOP_CART.ERROR');
    }
    cart.value = null;
  } finally {
    loading.value = false;
  }
};

const removeItem = async itemId => {
  try {
    await ShopAPI.removeItemFromCart(cart.value.id, itemId);
    fetchCart();
  } catch {
    // silently fail
  }
};

const updateQuantity = async (itemId, quantity) => {
  if (quantity < 1) {
    removeItem(itemId);
    return;
  }
  try {
    await ShopAPI.updateCartItem(cart.value.id, itemId, quantity);
    fetchCart();
  } catch {
    // silently fail
  }
};

// Watch for conversation changes
watch(
  () => props.conversationId,
  () => {
    fetchCart();
    lastMessageCount.value = messageCount.value;
  },
  { immediate: true }
);

// Watch for new messages - refresh cart when new messages arrive
watch(messageCount, newCount => {
  if (newCount > lastMessageCount.value && lastMessageCount.value > 0) {
    // Check if the latest message is related to cart
    const messages = currentChat.value?.messages || [];
    const latestMessage = messages[messages.length - 1];
    if (
      latestMessage?.content?.includes('Adicionar ao Carrinho') ||
      latestMessage?.content?.includes('ADD_CART')
    ) {
      // Small delay to let backend process the cart update
      setTimeout(fetchCart, 500);
    }
  }
  lastMessageCount.value = newCount;
});
</script>

<template>
  <div class="px-4 py-2 text-n-slate-12">
    <!-- Loading -->
    <div v-if="loading" class="flex justify-center items-center p-4">
      <Spinner size="32" class="text-n-brand" />
    </div>

    <!-- Error -->
    <div v-else-if="error" class="text-center text-n-ruby-12">
      {{ error }}
    </div>

    <!-- Empty -->
    <div v-else-if="!hasItems" class="text-center text-n-slate-11">
      {{ t('SHOP_CART.EMPTY') }}
    </div>

    <!-- Cart Items -->
    <div v-else>
      <div
        v-for="item in cart.items"
        :key="item.id"
        class="py-3 border-b border-n-weak last:border-b-0 flex flex-col gap-1.5"
      >
        <div class="flex justify-between items-start gap-2">
          <!-- Product Info -->
          <div class="flex gap-2 flex-1 min-w-0">
            <div
              v-if="item.product?.primary_image"
              class="size-10 rounded overflow-hidden flex-shrink-0"
            >
              <img
                :src="item.product.primary_image"
                :alt="item.product.name"
                class="w-full h-full object-cover"
              />
            </div>
            <div class="flex-1 min-w-0">
              <p class="font-medium text-n-slate-12 truncate">
                {{ item.product?.name }}
              </p>
              <p class="text-sm text-n-slate-11">
                {{ formatPrice(item.unit_price) }}
              </p>
            </div>
          </div>

          <!-- Quantity -->
          <div class="flex items-center gap-2">
            <button
              class="size-8 flex items-center justify-center rounded-md bg-n-alpha-2 hover:bg-n-alpha-3 text-n-slate-11"
              @click="updateQuantity(item.id, item.quantity - 1)"
            >
              <i class="i-lucide-minus size-5" />
            </button>
            <span class="w-6 text-center text-base font-semibold">
              {{ item.quantity }}
            </span>
            <button
              class="size-8 flex items-center justify-center rounded-md bg-n-alpha-2 hover:bg-n-alpha-3 text-n-slate-11"
              @click="updateQuantity(item.id, item.quantity + 1)"
            >
              <i class="i-lucide-plus size-5" />
            </button>
            <button
              class="size-8 flex items-center justify-center rounded-md bg-n-ruby-2 hover:bg-n-ruby-3 text-n-ruby-11 hover:text-n-ruby-12 ml-2"
              @click="removeItem(item.id)"
            >
              <i class="i-lucide-trash-2 size-5" />
            </button>
          </div>
        </div>

        <!-- Item Total -->
        <div class="text-sm text-n-slate-11 text-right">
          {{ formatPrice(item.total_price) }}
        </div>
      </div>

      <!-- Cart Total -->
      <div class="pt-3 flex justify-between items-center">
        <span class="text-n-slate-11">
          {{ itemCountLabel }}
        </span>
        <span class="font-semibold text-n-slate-12">
          {{ formatPrice(cart.subtotal) }}
        </span>
      </div>
    </div>
  </div>
</template>
