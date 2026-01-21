const HORIZONTAL_SPACING = 250;
const VERTICAL_SPACING = 120;
const START_X = 100;
const START_Y = 200;

/**
 * Obtém a posição salva ou calcula uma nova
 */
function getNodePosition(savedPosition, defaultX, defaultY) {
  if (savedPosition && typeof savedPosition.x === 'number') {
    return { x: savedPosition.x, y: savedPosition.y };
  }
  return { x: defaultX, y: defaultY };
}

/**
 * Converte uma automação para nodes e edges do VueFlow
 * @param {Object} automation - Objeto de automação
 * @returns {Object} { nodes, edges }
 */
export function automationToFlow(automation) {
  if (!automation || !automation.event_name) {
    return { nodes: [], edges: [] };
  }

  const nodes = [];
  const edges = [];
  let currentX = START_X;
  const currentY = START_Y;

  // 1. Criar nó de trigger - usar posição salva se disponível
  const triggerPosition = getNodePosition(
    automation.flow_trigger_position,
    currentX,
    currentY
  );
  const triggerNode = {
    id: 'trigger',
    type: 'trigger',
    position: triggerPosition,
    draggable: true,
    data: {
      event_name: automation.event_name || 'conversation_created',
      label: 'trigger',
    },
  };
  nodes.push(triggerNode);
  currentX += HORIZONTAL_SPACING;

  // 2. Criar nós de condições
  const conditions = automation.conditions || [];
  let lastConditionId = 'trigger';

  conditions.forEach((condition, index) => {
    const conditionId = `condition-${index}`;
    // Usar posição salva ou calcular nova (com offset vertical para cada condição)
    const conditionPosition = getNodePosition(
      condition.flow_position,
      currentX,
      currentY + index * VERTICAL_SPACING
    );

    const conditionNode = {
      id: conditionId,
      type: 'condition',
      position: conditionPosition,
      draggable: true,
      data: {
        ...condition,
        index,
        label: 'condition',
        queryOperator: condition.query_operator || null,
      },
    };
    nodes.push(conditionNode);

    // Criar edge do trigger/última condição para esta condição
    edges.push({
      id: `edge-${lastConditionId}-${conditionId}`,
      source: lastConditionId,
      target: conditionId,
      type: 'smoothstep',
      animated: true,
    });

    lastConditionId = conditionId;
    // Só avança X se não tiver posição salva
    if (!condition.flow_position) {
      currentX += HORIZONTAL_SPACING;
    }
  });

  // Ajustar currentX para ações se houver condições com posições salvas
  if (
    conditions.length > 0 &&
    !conditions[conditions.length - 1].flow_position
  ) {
    // currentX já está correto
  } else if (conditions.length > 0) {
    // Calcular X baseado na última condição
    const lastCondition = conditions[conditions.length - 1];
    currentX =
      (lastCondition.flow_position?.x || currentX) + HORIZONTAL_SPACING;
  }

  // 3. Criar nós de ações
  const actions = automation.actions || [];
  let lastActionId = lastConditionId;

  actions.forEach((action, index) => {
    const actionId = `action-${index}`;
    // Usar posição salva ou calcular nova (com offset vertical para cada ação)
    const actionPosition = getNodePosition(
      action.flow_position,
      currentX,
      currentY + index * VERTICAL_SPACING
    );

    const actionNode = {
      id: actionId,
      type: 'action',
      position: actionPosition,
      draggable: true,
      data: {
        ...action,
        index,
        label: 'action',
      },
    };
    nodes.push(actionNode);

    // Criar edge da última condição/última ação para esta ação
    edges.push({
      id: `edge-${lastActionId}-${actionId}`,
      source: lastActionId,
      target: actionId,
      type: 'smoothstep',
      animated: true,
    });

    lastActionId = actionId;
    // Só avança X se não tiver posição salva
    if (!action.flow_position) {
      currentX += HORIZONTAL_SPACING;
    }
  });

  return { nodes, edges };
}

/**
 * Converte nodes e edges do VueFlow para uma automação
 * @param {Array} nodes - Array de nodes do VueFlow
 * @param {Array} edges - Array de edges do VueFlow
 * @returns {Object} Objeto de automação com posições salvas
 */
export function flowToAutomation(nodes, edges) {
  if (!nodes || nodes.length === 0) {
    return {
      event_name: 'conversation_created',
      conditions: [],
      actions: [],
    };
  }

  // Ordenar nodes por posição X (esquerda para direita)
  const sortedNodes = [...nodes].sort((a, b) => a.position.x - b.position.x);

  // Encontrar o trigger node e salvar sua posição
  const triggerNode = sortedNodes.find(node => node.type === 'trigger');
  const eventName = triggerNode?.data?.event_name || 'conversation_created';
  const triggerPosition = triggerNode?.position || null;

  // Criar mapa de edges por source para facilitar busca
  const edgesBySource = {};
  edges.forEach(edge => {
    if (!edgesBySource[edge.source]) {
      edgesBySource[edge.source] = [];
    }
    edgesBySource[edge.source].push(edge);
  });

  // Extrair condições seguindo o fluxo de conexões
  const conditions = [];
  let currentNodeId = triggerNode?.id || 'trigger';

  // Seguir as conexões do trigger até encontrar ações
  while (
    edgesBySource[currentNodeId] &&
    edgesBySource[currentNodeId].length > 0
  ) {
    const nextEdge = edgesBySource[currentNodeId][0];
    const nextNode = sortedNodes.find(node => node.id === nextEdge.target);

    if (!nextNode) break;

    if (nextNode.type === 'condition') {
      const conditionData = { ...nextNode.data };
      // Remover campos específicos do VueFlow
      delete conditionData.label;
      delete conditionData.index;
      // Preservar query_operator se existir
      if (conditionData.queryOperator !== undefined) {
        conditionData.query_operator = conditionData.queryOperator;
        delete conditionData.queryOperator;
      }
      // Salvar posição do nó
      conditionData.flow_position = { ...nextNode.position };
      conditions.push(conditionData);
    } else if (nextNode.type === 'action') {
      // Chegamos nas ações, parar aqui
      break;
    }

    currentNodeId = nextNode.id;
  }

  // Extrair ações seguindo o fluxo de conexões
  const actions = [];
  // Encontrar o primeiro nó de ação
  const firstActionEdge = edges.find(
    edge => sortedNodes.find(node => node.id === edge.target)?.type === 'action'
  );

  if (firstActionEdge) {
    // Helper to find node by ID
    const findNodeById = nodeId => sortedNodes.find(node => node.id === nodeId);

    // Helper to find next action edge
    const findNextActionEdge = nodeId => {
      return edgesBySource[nodeId]?.find(
        edge => findNodeById(edge.target)?.type === 'action'
      );
    };

    currentNodeId = firstActionEdge.target;

    while (currentNodeId) {
      const actionNode = findNodeById(currentNodeId);
      if (!actionNode || actionNode.type !== 'action') break;

      const actionData = { ...actionNode.data };
      // Remover campos específicos do VueFlow
      delete actionData.label;
      delete actionData.index;
      // Salvar posição do nó
      actionData.flow_position = { ...actionNode.position };
      actions.push(actionData);

      // Próxima ação
      const nextEdge = findNextActionEdge(currentNodeId);
      currentNodeId = nextEdge?.target;
    }
  }

  return {
    event_name: eventName,
    conditions,
    actions,
    // Salvar posição do trigger
    flow_trigger_position: triggerPosition,
  };
}

/**
 * Composable para conversão bidirecional entre automação e VueFlow
 */
export function useAutomationFlowConverter() {
  return {
    automationToFlow,
    flowToAutomation,
  };
}
