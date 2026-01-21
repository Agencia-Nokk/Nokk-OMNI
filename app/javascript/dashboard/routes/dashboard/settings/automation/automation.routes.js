import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import SettingsContent from '../Wrapper.vue';
import Automation from './Index.vue';
import AutomationEditor from './AutomationEditor.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/automation'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'automation_list', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'automation_list',
          component: Automation,
          meta: {
            featureFlag: FEATURE_FLAGS.AUTOMATIONS,
            permissions: ['administrator'],
          },
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/settings/automation'),
      component: SettingsContent,
      props: () => ({
        headerTitle: 'AUTOMATION.HEADER',
        icon: 'flash-settings',
        showBackButton: true,
      }),
      children: [
        {
          path: 'new',
          name: 'automation_new',
          component: AutomationEditor,
          meta: {
            featureFlag: FEATURE_FLAGS.AUTOMATIONS,
            permissions: ['administrator'],
          },
        },
        {
          path: ':automationId/edit',
          name: 'automation_edit',
          component: AutomationEditor,
          meta: {
            featureFlag: FEATURE_FLAGS.AUTOMATIONS,
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
