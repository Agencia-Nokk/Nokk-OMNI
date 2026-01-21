<script setup>
import { nextTick, ref, watch, computed } from 'vue';
import { useTrack } from 'dashboard/composables';
import { COPILOT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useUISettings } from 'dashboard/composables/useUISettings';

import CopilotInput from './CopilotInput.vue';
import CopilotLoader from './CopilotLoader.vue';
import CopilotAgentMessage from './CopilotAgentMessage.vue';
import CopilotAssistantMessage from './CopilotAssistantMessage.vue';
import CopilotThinkingGroup from './CopilotThinkingGroup.vue';
import ToggleCopilotAssistant from './ToggleCopilotAssistant.vue';
import CopilotEmptyState from './CopilotEmptyState.vue';
import CopilotThreadsList from './CopilotThreadsList.vue';
import SidebarActionsHeader from 'dashboard/components-next/SidebarActionsHeader.vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  messages: {
    type: Array,
    default: () => [],
  },
  conversationInboxType: {
    type: String,
    required: true,
  },
  assistants: {
    type: Array,
    default: () => [],
  },
  activeAssistant: {
    type: Object,
    default: () => ({}),
  },
  threads: {
    type: Array,
    default: () => [],
  },
  activeThreadId: {
    type: Number,
    default: null,
  },
});

const emit = defineEmits([
  'sendMessage',
  'reset',
  'setAssistant',
  'selectThread',
]);

const { t } = useI18n();

const showHistory = ref(false);

const sendMessage = message => {
  emit('sendMessage', message);
  useTrack(COPILOT_EVENTS.SEND_MESSAGE);
};

const chatContainer = ref(null);

const scrollToBottom = async () => {
  await nextTick();
  if (chatContainer.value) {
    chatContainer.value.scrollTop = chatContainer.value.scrollHeight;
  }
};

const groupedMessages = computed(() => {
  const result = [];
  let thinkingGroup = [];
  props.messages.forEach(message => {
    if (message.message_type === 'assistant_thinking') {
      thinkingGroup.push(message);
    } else {
      if (thinkingGroup.length > 0) {
        result.push({
          id: thinkingGroup[0].id,
          message_type: 'thinking_group',
          messages: thinkingGroup,
        });
        thinkingGroup = [];
      }
      result.push(message);
    }
  });
  if (thinkingGroup.length > 0) {
    result.push({
      id: thinkingGroup[0].id,
      message_type: 'thinking_group',
      messages: thinkingGroup,
    });
  }
  return result;
});

const isLastMessageFromAssistant = computed(() => {
  return (
    groupedMessages.value[groupedMessages.value.length - 1].message_type ===
    'assistant'
  );
});

const { updateUISettings } = useUISettings();

const closeCopilotPanel = () => {
  updateUISettings({
    is_copilot_panel_open: false,
    is_contact_sidebar_open: false,
  });
};

const handleSidebarAction = action => {
  if (action === 'reset') {
    emit('reset');
    showHistory.value = false;
  } else if (action === 'history') {
    showHistory.value = !showHistory.value;
  }
};

const handleSelectThread = thread => {
  emit('selectThread', thread);
  showHistory.value = false;
};

const handleNewThread = () => {
  emit('reset');
  showHistory.value = false;
};

const hasAssistants = computed(() => props.assistants.length > 0);
const hasMessages = computed(() => props.messages.length > 0);
const copilotButtons = computed(() => {
  const buttons = [];

  if (props.threads.length > 0) {
    buttons.push({
      key: 'history',
      icon: 'i-lucide-history',
      tooltip: t('CAPTAIN.COPILOT.HISTORY'),
    });
  }

  if (hasMessages.value) {
    buttons.push({
      key: 'reset',
      icon: 'i-lucide-refresh-ccw',
      tooltip: t('CAPTAIN.COPILOT.RESET'),
    });
  }

  return buttons;
});
watch(
  [() => props.messages],
  () => {
    scrollToBottom();
  },
  { deep: true }
);
</script>

<template>
  <div class="flex flex-col h-full text-sm leading-6 tracking-tight w-full">
    <SidebarActionsHeader
      :title="$t('CAPTAIN.COPILOT.TITLE')"
      :buttons="copilotButtons"
      @click="handleSidebarAction"
      @close="closeCopilotPanel"
    />
    <div v-if="showHistory" class="flex-1 flex overflow-hidden">
      <CopilotThreadsList
        :threads="threads"
        :active-thread-id="activeThreadId"
        @select-thread="handleSelectThread"
        @new-thread="handleNewThread"
      />
    </div>
    <div
      v-else
      ref="chatContainer"
      class="flex-1 flex px-4 py-4 overflow-y-auto items-start"
    >
      <div v-if="hasMessages" class="space-y-6 flex-1 flex flex-col w-full">
        <template v-for="(item, index) in groupedMessages" :key="item.id">
          <CopilotAgentMessage
            v-if="item.message_type === 'user'"
            :message="item.message"
          />
          <CopilotAssistantMessage
            v-else-if="item.message_type === 'assistant'"
            :message="item.message"
            :is-last-message="index === groupedMessages.length - 1"
            :conversation-inbox-type="conversationInboxType"
          />
          <CopilotThinkingGroup
            v-else
            :messages="item.messages"
            :default-collapsed="isLastMessageFromAssistant"
          />
        </template>

        <CopilotLoader v-if="!isLastMessageFromAssistant" />
      </div>
      <CopilotEmptyState
        v-else
        :has-assistants="hasAssistants"
        @use-suggestion="sendMessage"
      />
    </div>

    <div class="mx-3 mt-px mb-2">
      <div class="flex items-center gap-2 justify-between w-full mb-1">
        <ToggleCopilotAssistant
          v-if="assistants.length > 1"
          :assistants="assistants"
          :active-assistant="activeAssistant"
          @set-assistant="$event => emit('setAssistant', $event)"
        />
        <div v-else />
      </div>
      <CopilotInput
        v-if="hasAssistants"
        class="mb-1 w-full"
        @send="sendMessage"
      />
    </div>
  </div>
</template>
