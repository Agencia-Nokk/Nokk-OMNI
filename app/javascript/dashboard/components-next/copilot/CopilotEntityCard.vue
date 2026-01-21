<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import Icon from '../icon/Icon.vue';

const props = defineProps({
  entity: {
    type: Object,
    required: true,
  },
});

const router = useRouter();
const { accountId } = useAccount();

const entityConfig = computed(() => {
  const configs = {
    automation_rule: {
      icon: 'i-lucide-workflow',
      route: `/app/accounts/${accountId.value}/settings/automation/${props.entity.id}/edit`,
    },
    macro: {
      icon: 'i-lucide-zap',
      route: `/app/accounts/${accountId.value}/settings/macros/${props.entity.id}/edit`,
    },
    label: {
      icon: 'i-lucide-tag',
      route: `/app/accounts/${accountId.value}/settings/labels`,
    },
    canned_response: {
      icon: 'i-lucide-message-square-quote',
      route: `/app/accounts/${accountId.value}/settings/canned-response/list`,
    },
    agent: {
      icon: 'i-lucide-user',
      route: `/app/accounts/${accountId.value}/settings/agents/list`,
    },
    team: {
      icon: 'i-lucide-users',
      route: `/app/accounts/${accountId.value}/settings/teams/list`,
    },
    agent_bot: {
      icon: 'i-lucide-bot',
      route: `/app/accounts/${accountId.value}/settings/agent-bots`,
    },
    custom_attribute: {
      icon: 'i-lucide-list-plus',
      route: `/app/accounts/${accountId.value}/settings/custom-attributes/list`,
    },
    custom_role: {
      icon: 'i-lucide-shield-check',
      route: `/app/accounts/${accountId.value}/settings/custom-roles/list`,
    },
  };
  return configs[props.entity.type] || { icon: 'i-lucide-file', route: '#' };
});

const navigateToEntity = () => {
  router.push(entityConfig.value.route);
};
</script>

<template>
  <button
    class="w-full px-3 py-2 rounded-md border border-n-weak bg-n-slate-2 text-n-slate-11 flex items-center justify-between hover:bg-n-slate-3 transition-colors"
    @click="navigateToEntity"
  >
    <span class="flex items-center gap-2">
      <Icon :icon="entityConfig.icon" class="text-n-slate-10" />
      <span>{{ entity.name }}</span>
      <span v-if="entity.active === false" class="text-xs text-n-amber-11">
        ({{ $t('CAPTAIN.COPILOT.INACTIVE') }})
      </span>
    </span>
    <Icon icon="i-lucide-chevron-right" />
  </button>
</template>
