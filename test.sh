#/bin/bash


ARTIFACTS_DIR=../lido-cosmos-hub-contracts/artifacts/

VAL=junovalcons1fq9ljyhtaucz8q2ueyzd84nszpftp2w06ztxcd

RES=$(../juno/bin/junod tx wasm store ${ARTIFACTS_DIR}lido_cosmos_hub.wasm --from swelf --gas 50000000  --chain-id testing --broadcast-mode=block --gas-prices 0.025ucosm  -y --output json)
HUB_CODE_ID=$(echo $RES | jq -r '.logs[0].events[1].attributes[0].value')
echo $RES
echo $HUB_CODE_ID

RES=$(../juno/bin/junod tx wasm store ${ARTIFACTS_DIR}lido_cosmos_rewards_dispatcher.wasm --from swelf --gas 50000000  --chain-id testing --broadcast-mode=block --gas-prices 0.025ucosm  -y --output json)
DISPATHER_CODE_ID=$(echo $RES | jq -r '.logs[0].events[1].attributes[0].value')
echo $RES
echo $DISPATHER_CODE_ID

RES=$(../juno/bin/junod tx wasm store ${ARTIFACTS_DIR}lido_cosmos_token_statom.wasm --from swelf --gas 50000000  --chain-id testing --broadcast-mode=block --gas-prices 0.025ucosm  -y --output json)
TOKEN_CODE_ID=$(echo $RES | jq -r '.logs[0].events[1].attributes[0].value')
echo $RES
echo $TOKEN_CODE_ID

RES=$(../juno/bin/junod tx wasm store ${ARTIFACTS_DIR}lido_cosmos_validators_registry.wasm --from swelf --gas 50000000  --chain-id testing --broadcast-mode=block --gas-prices 0.025ucosm  -y --output json)
VALIDATORS_CODE_ID=$(echo $RES | jq -r '.logs[0].events[1].attributes[0].value')
echo $RES
echo $VALIDATORS_CODE_ID


INIT_HUB='{"epoch_period": 10,"underlying_coin_denom": "ustake","unbonding_period": 10}'

RES=$(../juno/bin/junod tx wasm instantiate $HUB_CODE_ID "$INIT_HUB" --from swelf --admin juno16g2rahf5846rxzp3fwlswy08fz8ccuwk03k57y -y --chain-id testing --output json --broadcast-mode=block --label "init" )
echo $RES
HUB_ADDRESS=$(echo $RES | jq -r '.logs[0].events[0].attributes[0].value')
echo $HUB_ADDRESS


INIT_DISPATHER="{\"hub_contract\":\"$HUB_ADDRESS\",\"statom_reward_denom\":\"ustake\",\"lido_fee_address\":\"juno16g2rahf5846rxzp3fwlswy08fz8ccuwk03k57y\",\"lido_fee_rate\": \"0.005\"}"
echo $INIT_DISPATHER
RES=$(../juno/bin/junod tx wasm instantiate $DISPATHER_CODE_ID "$INIT_DISPATHER" --from swelf --admin juno16g2rahf5846rxzp3fwlswy08fz8ccuwk03k57y -y --chain-id testing --output json --broadcast-mode=block --label "init" )
echo $RES
DISPATHER_ADDRESS=$(echo $RES | jq -r '.logs[0].events[0].attributes[0].value')
echo $DISPATHER_ADDRESS


INIT_TOKEN="{\"hub_contract\":\"$HUB_ADDRESS\",\"name\":\"STATOM\",\"symbol\":\"STATOM\",\"decimals\":6,\"initial_balances\":[]}"
echo $INIT_TOKEN
RES=$(../juno/bin/junod tx wasm instantiate $TOKEN_CODE_ID "$INIT_TOKEN" --from swelf --admin juno16g2rahf5846rxzp3fwlswy08fz8ccuwk03k57y -y --chain-id testing --output json --broadcast-mode=block --label "init" )
echo $RES
TOKEN_ADDRESS=$(echo $RES | jq -r '.logs[0].events[0].attributes[0].value')
echo $TOKEN_ADDRESS



INIT_VALIDATORS="{\"hub_contract\":\"$HUB_ADDRESS\",\"registry\":[]}"
echo $INIT_VALIDATORS
RES=$(../juno/bin/junod tx wasm instantiate $VALIDATORS_CODE_ID "$INIT_VALIDATORS" --from swelf --admin juno16g2rahf5846rxzp3fwlswy08fz8ccuwk03k57y -y --chain-id testing --output json --broadcast-mode=block --label "init" )
echo $RES
VALIDATORS_ADDRESS=$(echo $RES | jq -r '.logs[0].events[0].attributes[0].value')
echo $VALIDATORS_ADDRESS

RES=$(../juno/bin/junod query staking validators --output json)
VAL=$(echo $RES | jq -r '.validators[0].operator_address')
echo $VAL


UPDATE_MSG="{\"update_config\":{\"rewards_dispatcher_contract\":\"$DISPATHER_ADDRESS\",\"statom_token_contract\":\"$TOKEN_ADDRESS\",\"validators_registry_contract\":\"$VALIDATORS_ADDRESS\"}}"
echo $UPDATE_MSG
RES=$(../juno/bin/junod tx wasm execute $HUB_ADDRESS "$UPDATE_MSG" --from swelf -y --chain-id testing --output json --broadcast-mode=block  )
echo $RES

REGISTER_VALIDATOR="{\"add_validator\":{\"validator\":{\"address\":\"$VAL\"}}}"
echo $REGISTER_VALIDATOR
RES=$(../juno/bin/junod tx wasm execute $VALIDATORS_ADDRESS "$REGISTER_VALIDATOR" --from swelf  -y --chain-id testing --output json --broadcast-mode=block  )
echo $RES

BOND='{"bond_for_st_atom":{}}'
echo $BOND
RES=$(../juno/bin/junod tx wasm execute $HUB_ADDRESS "$BOND" --from swelf -y --chain-id testing --output json --broadcast-mode=block --amount 100000000ustake --gas-prices 0.025ucosm --gas 1000000)
echo $RES

DISPATCH_REWARDS='{"dispatch_rewards":{}}'
echo $DISPATCH_REWARDS
RES=$(../juno/bin/junod tx wasm execute $HUB_ADDRESS "$DISPATCH_REWARDS" --from swelf -y --chain-id testing --output json --broadcast-mode=block  --gas-prices 0.025ucosm --gas 1000000)
echo $RES


UNBOND="{\"send\":{\"contract\":\"${HUB_ADDRESS}\",\"amount\":\"90000\",\"msg\":\"eyJ1bmJvbmQiOnt9fQ==\"}}"
echo $UNBOND
RES=$(../juno/bin/junod tx wasm execute $TOKEN_ADDRESS "$UNBOND" --from swelf -y --chain-id testing --output json --broadcast-mode=block --gas-prices 0.025ucosm --gas 1000000)
echo $RES

./bin/junod query wasm contract-state smart ${HUB_ADDRESS} --ascii '{"all_history":{}}'

./bin/junod query wasm contract-state smart ${HUB_ADDRESS} --ascii '{"current_batch":{}}'
