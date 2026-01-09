## Autonomous-Lane-Changing
자율주행 차선변경 모듈 구현 및 검증

## Description
본 프로젝는 Single Lane Change Planner and Controller를 구현 및 검증을 한다.

차량에 탑재된 센서를 사용하여 주변 환경의 주요 장애물(MIO)을 감지하고, 이러한 장애물을 피하는 최적의 경로를 식별한 후, 자율주행 차량을 해당 경로를 따라 조종하는 process를 따른다.

시뮬레이션 결과에 따른 검증값을 통해 제어기의 어떤 가중치 값들을 변경했을때 최적의 결과값이 나오는지 판단하는 것이 최종 목표이다.

## Model Architecture
<img width="813" height="533" alt="image" src="https://github.com/user-attachments/assets/81f1dc53-4f50-4827-b1f6-c6172da2daa7" />

환경 정보를 센서 데이터로 변환하는 역할

- 작동 과정
1. 외부에서 들어온 EgoActor (현재 내 차의 위치) 정보를 받아서
2. 그 위치에서 보이는 차선과 주변 차량 정보를 계산해서 내보냄

- 출력 신호들
1. **`TargetActorsEgo`**: 내 차 기준으로 주변 차가 어디 있는지(상대 좌표). -> **Planner(판단)** 블록으로 
2. **`LaneBoundaries`**: 내 차 기준 차선 정보. -> **Planner** 및 **Controller**로
3.  **`TargetActorsWorld`**: 절대 좌표상 주변 차량 위치. -> 주로 시각화나 검증에 사용

<br>

<img width="939" height="339" alt="image" src="https://github.com/user-attachments/assets/f488e1a8-516f-4dc7-b14b-d106d1510e41" />

## 

1. Frenet State Converter (좌표 변환기) 
    
    : X,Y 좌표(cartesian)를 고속도로에 적합한 S, D 좌표(Frenet)으로 변환
    
    : **S (Longitudinal)**: 도로를 따라 얼마나 달렸는지 (주행 거리)
    
    : **D (Lateral)**: 도로 중심선에서 좌우로 얼마나 떨어져 있는지 (차선 위치)
    
2. Find MIOs (Most Important Objects - 중요 차량 선별)
    
    : 주변에 수많은 장애물(차량)들 중 나의 주행에 직접 영향을 주는 핵심 차량 6대 (MIO)만 골라냄
    
3. Terminal State Sampler (행동 결정 & 후보지 생성)
    
    : 앞으로 몇 초 뒤에 내 차가 어디에 있어야 하는지 후보지 생성
    
4. Motion Prediction(주변 차량 미래 예측)
    
    : 주변 차량(MIO)들이 **"다음 몇 초 동안 어떻게 움직일지"** 예측
    
5. Motion Planner (최적 경로 생성)
    
    : Cost function에 따라 여러 후보 경로에 점수를 매김 (안정성/편안함/효율성)
    
    : 가장 점수가 좋은 경로를 선택해서 Controller(제어기)로 보내줌

<br>

<img width="944" height="546" alt="image" src="https://github.com/user-attachments/assets/dea0d54d-6eff-4d37-b4a1-bd3eece1eb4f" />

입력 : RefPointOnPath(목표 경로)

- 버스 셀렉터를 통해 3개로 쪼개짐
    - **RefVelocity**: 목표 속도 (얼마나 빨리 달릴 것인가)
    - **RefCurvature**: 도로의 굽은 정도 (곡률)
    - **LatOffset**: 경로 중심에서 얼마나 벗어나야 하는지 (차선 변경 시 중요)

중간 전처리 과정

- `Virtual Lane Center` (가상 차선 중심 생성)
    
    - 차량이 따라가야 할 가상의 주행 중심선(Virtual Lane)을 생성
    
- `Preview Curvature` (미리보기 및 오차 계산)
    
    - 현재 속도를 고려해 앞으로 주행할 곳의 곡률을 미리 계산
    
    - 현재 내 차가 옆으로 얼마나 벗어났는지(**Lateral Deviation**), 각도는 얼마나 틀어졌는지(**Relative Yaw Angle**)를 계산
    

핵심 :`Path Following Controller` (경로 추종 제어기)

- MPC 알고리즘이 내장
- 입력받은 오차를 0으로 만들기 위해 노력
- 출력으로 최종적으로 계산된 가속도와 조향각도가 나가서 `Vehicle Dynamics` 블록으로 전달

<br>

<img width="767" height="315" alt="image" src="https://github.com/user-attachments/assets/bfd6144d-51a2-4a76-92b1-c4065bebb9bd" />
<img width="574" height="436" alt="image" src="https://github.com/user-attachments/assets/8bc82964-ce59-4acb-9543-fb8bea48015c" />

1. Collision Detection (안전성 평가)

- 입력값 : `TargetActors` (장애물 위치), `Lane Boundaries` (차선 정보), `TrajectoryInfo` (경로 정보), `PlannerParams` (설정값), `Velocity` (내 속도)
- 주요 평가 항목
    - **`Verify No Collision` (충돌 여부)**: 내 차가 장애물 차량이나 가드레일과 부딪혔는지 감시. 만약 닿았다면 시뮬레이션 실패임**(장애물 회피 시나리오에서 가장 중요하게 봐야 할 부분)**
    - **`Verify Time Gap` (안전 거리 확보)**: 앞차와의 거리(차간 시간)가 적절한지 봄www
    - **`Verify Safety` (종합 안전)**: 충돌 임박 시간(TTC) 등을 계산해서 위험한 상황인지 판단

2. Jerk Metrics (승차감 평가)

- 저크 : 가속도의 변화율 (급출발, 급제동, 급핸들 조작)
    - 저크가 높다 = 목이 꺾이거나 몸이 쏠린다
    - 차가 얼마나 부드럽게 움직였는지 저크라는 단위로 평가
- 주요 평가 항목
    - **`Verify Longitudinal Jerk` (앞뒤 쏠림)**: 엑셀이나 브레이크를 너무 확확 밟지 않았는지 체크
    - **`Verify Lateral Jerk` (좌우 쏠림)**: 핸들을 너무 급격하게 꺾지 않았는지 체크
 
## Results
본 실험은 핸들의 조향각 변화율 가중치를 달리 했을 때 경로 추종을 얼마나 정확하게 하는 지에 초점을 두었다

- 최적값 튜닝

![KakaoTalk_Video_2026-01-09-22-33-39](https://github.com/user-attachments/assets/fd89299d-eff6-444c-b046-f7e6266a6531)

- 너무 낮은 가중치 (급격한 조향각 변경)

![KakaoTalk_Video_2026-01-09-22-33-49](https://github.com/user-attachments/assets/a5e497dd-9e5b-44bc-9b9f-d4c36d93853c)

- 너무 높은 가중치 (경로 추종 실패)

![KakaoTalk_Video_2026-01-09-22-33-59](https://github.com/user-attachments/assets/2f604f6c-7e34-4a92-bfe5-cc27d8a3c233)

<br>

## 연구결과 및 고찰

### 연구결과
- 동적 구속 조건 적용을 통한 최적화 
  - 실제 차량 하드웨어의 물리적 한계를 반영하여 시뮬레이션 결과가 실제 차량에 더 유연하게 적용될 수 있도록 최적화

- 시뮬레이션 기반 성능비교 
  - 개선 전후의 시뮬레이션 영상을 통해 경로 추종 성능이 향상되었음을 확인

- 다각적 지표 분석
  - Metrics Assessment 과정을 통해 충돌 여부, 안전 거리, 차량 안전성, 그리고 승차감에 직결되는 저크 값들을 정량적으로 검증
 
## 향후 연구 필요성
- 상황 적응형 가중치 적용 필요
  - 현재는 하나의 가중치만을 변경했지만, 향후에는 도로의 마찰력(비,눈), 차량의 속도, 주변 교통 밀도에 따라 가중치를 실시간으로 변경할 필요성

- 엣지 케이스 테스트 필요
  - 현재 시나리오보다 더 복잡한 병목 구간이나 갑작스럽게 끼어드는 차량이 존재하는 상황 등에서도 안정적으로 작동하는지 테스트 필요성

- 센서 노이즈 고려 필요
  - 완벽한 데이터로 시뮬레이션을 돌리는 것이 아닌, 실제 센서에서 발생할 수 있는 노이즈나 통신 지연 같은 상황에서의 연구 필요성













