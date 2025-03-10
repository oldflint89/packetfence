import {
  BaseViewCollectionItem,
  BaseFormGroupToggleNYDefault
} from '@/views/Configuration/_components/new/'
import {
  BaseFormButtonBar,
  BaseFormGroupChosenOne,
  BaseFormGroupInput,
  BaseFormGroupInputNumber,
  BaseFormGroupInputPassword,
  BaseFormGroupTextarea,
  BaseFormGroupSwitch,
  BaseInput
} from '@/components/new/'
import BaseFormGroupInlineTrigger from '../../switches/_components/BaseFormGroupInlineTrigger'
import BaseFormGroupToggleStaticDynamicDefault from '../../switches/_components/BaseFormGroupToggleStaticDynamicDefault'
import BaseFormGroupType from '../../switches/_components/BaseFormGroupType'
import BaseInputToggleNetworkFrom from '../../switches/_components/BaseInputToggleNetworkFrom'
import TheForm from './TheForm'
import TheView from './TheView'

export {
  BaseFormButtonBar                       as FormButtonBar,

  BaseFormGroupToggleNYDefault            as FormGroupCliAccess,
  BaseFormGroupInputPassword              as FormGroupCliEnablePwd,
  BaseFormGroupInputPassword              as FormGroupCliPwd,
  BaseFormGroupChosenOne                  as FormGroupCliTransport,
  BaseFormGroupInput                      as FormGroupCliUser,
  BaseFormGroupInputNumber                as FormGroupCoaPort,
  BaseFormGroupInput                      as FormGroupControllerIp,
  BaseFormGroupChosenOne                  as FormGroupDeauthenticationMethod,
  BaseFormGroupInput                      as FormGroupDescription,
  BaseFormGroupInput                      as FormGroupDisconnectPort,
  BaseFormGroupToggleNYDefault            as FormGroupExternalPortalEnforcement,
  BaseFormGroupChosenOne                  as FormGroupGroup,
  BaseFormGroupInput                      as FormGroupIdentifier,
  BaseFormGroupInlineTrigger              as FormGroupInlineTrigger,
  BaseFormGroupInput                      as FormGroupMacSearchesMaxNb,
  BaseFormGroupInput                      as FormGroupMacSearchesSleepInterval,
  BaseFormGroupChosenOne                  as FormGroupMode,
  BaseFormGroupToggleNYDefault            as FormGroupRadiusDeauthUseConnector,
  BaseFormGroupInputPassword              as FormGroupRadiusSecret,
  BaseFormGroupTextarea                   as FormGroupRoleMapAccessList,
  BaseFormGroupInput                      as FormGroupRoleMapRole,
  BaseFormGroupInput                      as FormGroupRoleMapVpn,
  BaseFormGroupInput                      as FormGroupRoleMapUrl,
  BaseFormGroupInput                      as FormGroupRoleMapVlan,
  BaseFormGroupInput                      as FormGroupRoleMapInterface,
  BaseFormGroupInput                      as FormGroupSnmpAuthProtocolTrap,
  BaseFormGroupInputPassword              as FormGroupSnmpAuthPasswordTrap,
  BaseFormGroupInput                      as FormGroupSnmpCommunityRead,
  BaseFormGroupInput                      as FormGroupSnmpCommunityTrap,
  BaseFormGroupInput                      as FormGroupSnmpCommunityWrite,
  BaseFormGroupInputPassword              as FormGroupSnmpAuthPasswordRead,
  BaseFormGroupInput                      as FormGroupSnmpAuthProtocolRead,
  BaseFormGroupInput                      as FormGroupSnmpAuthProtocolWrite,
  BaseFormGroupInputPassword              as FormGroupSnmpAuthPasswordWrite,
  BaseFormGroupInput                      as FormGroupSnmpEngineIdentifier,
  BaseFormGroupInputPassword              as FormGroupSnmpPrivPasswordRead,
  BaseFormGroupInputPassword              as FormGroupSnmpPrivPasswordTrap,
  BaseFormGroupInputPassword              as FormGroupSnmpPrivPasswordWrite,
  BaseFormGroupInput                      as FormGroupSnmpPrivProtocolRead,
  BaseFormGroupInput                      as FormGroupSnmpPrivProtocolTrap,
  BaseFormGroupInput                      as FormGroupSnmpPrivProtocolWrite,
  BaseFormGroupToggleNYDefault            as FormGroupSnmpUseConnector,
  BaseFormGroupInput                      as FormGroupSnmpUserNameTrap,
  BaseFormGroupInput                      as FormGroupSnmpUserNameWrite,
  BaseFormGroupInput                      as FormGroupSnmpUserNameRead,
  BaseFormGroupChosenOne                  as FormGroupSnmpVersion,
  BaseFormGroupChosenOne                  as FormGroupSnmpVersionTrap,
  BaseFormGroupType                       as FormGroupType,
  BaseFormGroupInput                      as FormGroupUplink,
  BaseFormGroupToggleStaticDynamicDefault as FormGroupUplinkDynamic,
  BaseFormGroupToggleNYDefault            as FormGroupUseCoa,
  BaseFormGroupToggleNYDefault            as FormGroupUsePushAcls,
  BaseFormGroupToggleNYDefault            as FormGroupUseDownloadableAcls,
  BaseFormGroupInput                      as FormGroupDownloadableAclsLimit,
  BaseFormGroupInput                      as FormGroupAclsLimit,
  BaseFormGroupSwitch                     as FormGroupDeauthOnPrevious,
  BaseFormGroupToggleNYDefault            as FormGroupToggleAccessListMap,
  BaseFormGroupToggleNYDefault            as FormGroupToggleRoleMap,
  BaseFormGroupToggleNYDefault            as FormGroupToggleVpnMap,
  BaseFormGroupToggleNYDefault            as FormGroupToggleUrlMap,
  BaseFormGroupToggleNYDefault            as FormGroupToggleVlanMap,
  BaseFormGroupToggleNYDefault            as FormGroupToggleNetworkMap,
  BaseFormGroupToggleNYDefault            as FormGroupToggleInterfaceMap,
  BaseFormGroupToggleNYDefault            as FormGroupVoipEnabled,
  BaseFormGroupToggleNYDefault            as FormGroupVoipLldpDetect,
  BaseFormGroupToggleNYDefault            as FormGroupVoipCdpDetect,
  BaseFormGroupToggleNYDefault            as FormGroupVoipDhcpDetect,
  BaseFormGroupToggleNYDefault            as FormGroupPostMfaValidation,
  BaseFormGroupInputPassword              as FormGroupWebServicesPwd,
  BaseFormGroupChosenOne                  as FormGroupWebServicesTransport,
  BaseFormGroupInput                      as FormGroupWebServicesUser,

  BaseInput                               as InputRoleMapNetwork,
  BaseInputToggleNetworkFrom              as InputToggleNetworkFrom,

  BaseViewCollectionItem                  as BaseView,
  TheForm,
  TheView
}

