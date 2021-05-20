import { computed, toRefs } from '@vue/composition-api'
import { pfSearchConditionType as conditionType } from '@/globals/pfSearch'
import i18n from '@/utils/locale'

export const useItemTitle = (props) => {
  const {
    id,
    isClone,
    isNew
  } = toRefs(props)
  return computed(() => {
    switch (true) {
      case !isNew.value && !isClone.value:
        return i18n.t('Admin Role <code>{id}</code>', { id: id.value })
      case isClone.value:
        return i18n.t('Clone Admin Role <code>{id}</code>', { id: id.value })
      default:
        return i18n.t('New Admin Role')
    }
  })
}

export { useRouter } from '../_router'

export const useStore = (props, context, form) => {
  const {
    id,
    isClone
  } = toRefs(props)
  const { root: { $store } = {} } = context
  return {
    isLoading: computed(() => $store.getters['$_admin_roles/isLoading']),
    getOptions: () => $store.dispatch('$_admin_roles/options'),
    createItem: () => $store.dispatch('$_admin_roles/createAdminRole', form.value),
    deleteItem: () => $store.dispatch('$_admin_roles/deleteAdminRole', id.value),
    getItem: () => $store.dispatch('$_admin_roles/getAdminRole', id.value).then(item => {
      if (isClone.value) {
        item.id = `${item.id}-${i18n.t('copy')}`
        item.not_deletable = false
      }
      return item
    }),
    updateItem: () => $store.dispatch('$_admin_roles/updateAdminRole', form.value),
  }
}

import makeSearch from '@/views/Configuration/_store/factory/search'
import api from '../_api'
export const useSearch = makeSearch('adminRoles', {
  api,
  columns: [
    {
      key: 'selected',
      thStyle: 'width: 40px;', tdClass: 'p-0',
      locked: true
    },
    {
      key: 'id',
      label: 'Role Name', // i18n defer
      required: true,
      sortable: true,
      visible: true,
      searchable: true
    },
    {
      key: 'description',
      label: 'Description', // i18n defer
      sortable: true,
      visible: true,
      searchable: true
    },
    {
      key: 'buttons',
      class: 'text-right p-0',
      locked: true
    }
  ],
  fields: [
    {
      value: 'id',
      text: i18n.t('Role Name'),
      types: [conditionType.SUBSTRING]
    },
    {
      value: 'description',
      text: i18n.t('Description'),
      types: [conditionType.SUBSTRING]
    }
  ],
  sortBy: 'id',
  defaultCondition: () => ([{
    values: [
      { field: 'id', op: 'contains', value: null },
      { field: 'description', op: 'contains', value: null }
    ]
  }]),
  requestInterceptor: request => {
      // append query in request to omit NONE, ALL, ALL_PF_ONLY from request
      request.query.values = [
      ...request.query.values,
      { op: 'or', values: [ { field: 'id', op: 'not_equals', value: 'NONE' } ] },
      { op: 'or', values: [ { field: 'id', op: 'not_equals', value: 'ALL' } ] },
      { op: 'or', values: [ { field: 'id', op: 'not_equals', value: 'ALL_PF_ONLY' } ] }
    ]
    return request
  },
  /*
  responseInterceptor: response => { // strip NONE, ALL, ALL_PF_ONLY from results items
    let { items = [], ...rest } = response
    items = items.filter(({ id }) => !['NONE', 'ALL', 'ALL_PF_ONLY'].includes(id))
    return { items, ...rest }
  }
  */
})
