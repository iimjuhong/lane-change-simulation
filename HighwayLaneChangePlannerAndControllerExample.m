openProject("HLCPlannerAndController");
open_system('HLCPlannerAndControllerTestBench');
open_system('HLCPlannerAndControllerTestBench/Scenario and Environment')
open_system('HighwayLaneChangePlanner')
open_system('LaneChangeController')
open_system('HLCPlannerAndControllerTestBench/Metrics Assessment')
helperSLHLCPlannerAndControllerSetup('scenarioFcnName','scenario_LC_15_StopnGo_Curved')
mpcverbosity('off');
sim('HLCPlannerAndControllerTestBench','StopTime','5');
hLCPlot = findobj( 'Type', 'Figure', 'Name', 'Lane Change Status Plot');
if ~isempty(hLCPlot)
    close(hLCPlot);
end
sim('HLCPlannerAndControllerTestBench','StopTime','8');
hLCPlot = findobj( 'Type', 'Figure', 'Name', 'Lane Change Status Plot');
if ~isempty(hLCPlot)
    close(hLCPlot);
end
simout = sim('HLCPlannerAndControllerTestBench','StopTime','18');
hLCPlot = findobj( 'Type', 'Figure', 'Name', 'Lane Change Status Plot');
if ~isempty(hLCPlot)
    close(hLCPlot);
end
visualizatonObj = HelperAnalyzeLCPlannerSimulationResults(simout.logsout);
visualizatonObj.visualizeSimulationData
helperSLHLCPlannerAndControllerSetup('scenarioFcnName','scenario_LC_10_SingleLaneChange_Curved');
mpcverbosity('on');