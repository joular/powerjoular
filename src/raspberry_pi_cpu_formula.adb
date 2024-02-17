--
--  Copyright (c) 2020-2023, Adel Noureddine, Université de Pau et des Pays de l'Adour.
--  All rights reserved. This program and the accompanying materials
--  are made available under the terms of the
--  GNU General Public License v3.0 only (GPL-3.0-only)
--  which accompanies this distribution, and is available at:
--  https://www.gnu.org/licenses/gpl-3.0.en.html
--
--  Author : Adel Noureddine
--

with Ada.Text_IO; use Ada.Text_IO;

package body Raspberry_Pi_CPU_Formula is

    function Calculate_CPU_Power (CPU_Utilization : Long_Float; Platform_Name : String; Algorithm_Name : String) return Long_Float is
    begin
        -- Formulas are based on empirical experimentation and linear/polynomial regression

        if (Platform_Name = "rbp51.0-64") then
            if (Algorithm_Name = "linear") then
                return (3.457855981342954 * CPU_Utilization) + 4.403192179893827;
            elsif (Algorithm_Name = "polynomial") then
                return 8.71648242592654 + (-186.5634686 * (CPU_Utilization ** 1)) +
                    (2676.08397456 * (CPU_Utilization ** 2)) +
                        (-18839.18873015 * (CPU_Utilization ** 3)) +
                            (75110.3949109 * (CPU_Utilization ** 4)) +
                                (-180373.73562042 * (CPU_Utilization ** 5)) +
                                    (267380.23597063 * (CPU_Utilization ** 6)) +
                                        (-240403.81341249 * (CPU_Utilization ** 7)) +
                                            (120509.01405772 * (CPU_Utilization ** 8)) +
                                                (-25877.41360901 * (CPU_Utilization ** 9));
            else
                return 0.0;
            end if;
        end if;

        if (Platform_Name = "rbp4001.0-64") then
            if (Algorithm_Name = "linear") then
                return (5.025368568347057 * CPU_Utilization) + 1.8221330203847232;
            elsif (Algorithm_Name = "polynomial") then
                return 2.6630056198236938 + (0.82814554 * (CPU_Utilization ** 1)) +
                    (-112.17687631 * (CPU_Utilization ** 2)) +
                        (1753.99173239 * (CPU_Utilization ** 3)) +
                            (-10992.65341181 * (CPU_Utilization ** 4)) +
                                (35988.45610911 * (CPU_Utilization ** 5)) +
                                    (-66254.20051068 * (CPU_Utilization ** 6)) +
                                        (69071.21138567 * (CPU_Utilization ** 7)) +
                                            (-38089.87171735 * (CPU_Utilization ** 8)) +
                                                (8638.45610698 * (CPU_Utilization ** 9));
            else
                return 0.0;
            end if;
        end if;

        if (Platform_Name = "rbp4b1.2") then
            if (Algorithm_Name = "linear") then
                return (3.484191712285443 * CPU_Utilization) + 2.243353676359355;
            elsif (Algorithm_Name = "polynomial") then
                return 2.58542069543335 + (12.335449 * (CPU_Utilization ** 1)) +
                    (-248.010554 * (CPU_Utilization ** 2)) +
                        (2379.832320 * (CPU_Utilization ** 3)) +
                            (-11962.419149 * (CPU_Utilization ** 4)) +
                                (34444.268647 * (CPU_Utilization ** 5)) +
                                    (-58455.266502 * (CPU_Utilization ** 6)) +
                                        (57698.685016 * (CPU_Utilization ** 7)) +
                                            (-30618.557703 * (CPU_Utilization ** 8)) +
                                                (6752.265368 * (CPU_Utilization ** 9));
            else
                return 0.0;
            end if;
        end if;

        if (Platform_Name = "rbp4b1.2-64") then
            if (Algorithm_Name = "linear") then
                return (4.534426720546654 * CPU_Utilization) + 2.2856926184722672;
            elsif (Algorithm_Name = "polynomial") then
                return 3.039940056604439 + (-3.074225 * (CPU_Utilization ** 1)) +
                    (47.753114 * (CPU_Utilization ** 2)) +
                        (-271.974551 * (CPU_Utilization ** 3)) +
                            (879.966571 * (CPU_Utilization ** 4)) +
                                (-1437.466442 * (CPU_Utilization ** 5)) +
                                    (1133.325791 * (CPU_Utilization ** 6)) +
                                        (-345.134888 * (CPU_Utilization ** 7));
            else
                return 0.0;
            end if;
        end if;

        if (Platform_Name = "rbp4b1.1") then
            if (Algorithm_Name = "linear") then
                return (3.7120866521147464 * CPU_Utilization) + 2.2057553699838475;
            elsif (Algorithm_Name = "polynomial") then
                return 2.5718068562852086 + (2.794871 * (CPU_Utilization ** 1)) +
                    (-58.954883 * (CPU_Utilization ** 2)) +
                        (838.875781 * (CPU_Utilization ** 3)) +
                            (-5371.428686 * (CPU_Utilization ** 4)) +
                                (18168.842874 * (CPU_Utilization ** 5)) +
                                    (-34369.583554 * (CPU_Utilization ** 6)) +
                                        (36585.681749 * (CPU_Utilization ** 7)) +
                                            (-20501.307640 * (CPU_Utilization ** 8)) +
                                                (4708.331490 * (CPU_Utilization ** 9));
            else
                return 0.0;
            end if;
        end if;

        if (Platform_Name = "rbp4b1.1-64") then
            if (Algorithm_Name = "linear") then
                return (4.495800769695992 * CPU_Utilization) + 2.307256151537276;
            elsif (Algorithm_Name = "polynomial") then
                return 3.405685008777926 + (-11.834416 * (CPU_Utilization ** 1)) +
                    (137.312822 * (CPU_Utilization ** 2)) +
                        (-775.891511 * (CPU_Utilization ** 3)) +
                            (2563.399671 * (CPU_Utilization ** 4)) +
                                (-4783.024354 * (CPU_Utilization ** 5)) +
                                    (4974.960753 * (CPU_Utilization ** 6)) +
                                        (-2691.923074 * (CPU_Utilization ** 7)) +
                                            (590.355251 * (CPU_Utilization ** 8));
            else
                return 0.0;
            end if;
        end if;

        if (Platform_Name = "rbp3b+1.3") then
            if (Algorithm_Name = "linear") then
                return (3.298332817557656 * CPU_Utilization) + 2.002229902630705;
            elsif (Algorithm_Name = "polynomial") then
                return 2.484396997449118 + (2.933542 * (CPU_Utilization ** 1)) +
                    (-150.400134 * (CPU_Utilization ** 2)) +
                        (2278.690310 * (CPU_Utilization ** 3)) +
                            (-15008.559279 * (CPU_Utilization ** 4)) +
                                (51537.315529 * (CPU_Utilization ** 5)) +
                                    (-98756.887779 * (CPU_Utilization ** 6)) +
                                        (106478.929766 * (CPU_Utilization ** 7)) +
                                            (-60432.910139 * (CPU_Utilization ** 8)) +
                                                (14053.677709 * (CPU_Utilization ** 9));
            else
                return 0.0;
            end if;
        end if;

        if (Platform_Name = "rbp3b1.2") then
            if (Algorithm_Name = "linear") then
                return (3.477373034437569 * CPU_Utilization) + 1.078203625009793;
            elsif (Algorithm_Name = "polynomial") then
                return 1.524116907651687 + (10.053851 * (CPU_Utilization ** 1)) +
                    (-234.186930 * (CPU_Utilization ** 2)) +
                        (2516.322119 * (CPU_Utilization ** 3)) +
                            (-13733.555536 * (CPU_Utilization ** 4)) +
                                (41739.918887 * (CPU_Utilization ** 5)) +
                                    (-73342.794259 * (CPU_Utilization ** 6)) +
                                        (74062.644914 * (CPU_Utilization ** 7)) +
                                            (-39909.425362 * (CPU_Utilization ** 8)) +
                                                (8894.110508 * (CPU_Utilization ** 9));
            else
                return 0.0;
            end if;
        end if;

        if (Platform_Name = "rbp2b1.1") then
            if (Algorithm_Name = "linear") then
                return (1.1488378157140957 * CPU_Utilization) + 1.2902541858404697;
            elsif (Algorithm_Name = "polynomial") then
                return 1.3596870187778196 + (5.135090 * (CPU_Utilization ** 1)) +
                    (-103.296366 * (CPU_Utilization ** 2)) +
                        (1027.169748 * (CPU_Utilization ** 3)) +
                            (-5323.639404 * (CPU_Utilization ** 4)) +
                                (15592.036875 * (CPU_Utilization ** 5)) +
                                    (-26675.601585 * (CPU_Utilization ** 6)) +
                                        (26412.963366 * (CPU_Utilization ** 7)) +
                                            (-14023.471809 * (CPU_Utilization ** 8)) +
                                                (3089.786200 * (CPU_Utilization ** 9));
            else
                return 0.0;
            end if;
        end if;

        if (Platform_Name = "rbp1b+1.2") then
            if (Algorithm_Name = "linear") then
                return (0.12201084670300544 * CPU_Utilization) + 1.3142771210514672;
            elsif (Algorithm_Name = "polynomial") then
                return 1.2513999338064061 + (1.857815 * (CPU_Utilization ** 1)) +
                    (-18.109537 * (CPU_Utilization ** 2)) +
                        (101.531231 * (CPU_Utilization ** 3)) +
                            (-346.386617 * (CPU_Utilization ** 4)) +
                                (749.560352 * (CPU_Utilization ** 5)) +
                                    (-1028.802514 * (CPU_Utilization ** 6)) +
                                        (863.877618 * (CPU_Utilization ** 7)) +
                                            (-403.270951 * (CPU_Utilization ** 8)) +
                                                (79.925932 * (CPU_Utilization ** 9));
            else
                return 0.0;
            end if;
        end if;

        if (Platform_Name = "rbp1b2") then
            if (Algorithm_Name = "linear") then
                return (0.1423962237746236 * CPU_Utilization) + 2.911666160370786;
            elsif (Algorithm_Name = "polynomial") then
                return 2.826093843916506 + (3.539891 * (CPU_Utilization ** 1)) +
                    (-43.586963 * (CPU_Utilization ** 2)) +
                        (282.488560 * (CPU_Utilization ** 3)) +
                            (-1074.116844 * (CPU_Utilization ** 4)) +
                                (2537.679443 * (CPU_Utilization ** 5)) +
                                    (-3761.784242 * (CPU_Utilization ** 6)) +
                                        (3391.045904 * (CPU_Utilization ** 7)) +
                                            (-1692.840870 * (CPU_Utilization ** 8)) +
                                                (357.800968 * (CPU_Utilization ** 9));
            else
                return 0.0;
            end if;
        end if;

        if (Platform_Name = "rbpzw1.1") then
            if (Algorithm_Name = "linear") then
                return (0.47328964159919246 * CPU_Utilization) + 0.9200829295923802;
            elsif (Algorithm_Name = "polynomial") then
                return 0.8551610676717238 + (7.207151 * (CPU_Utilization ** 1)) +
                    (-135.517893 * (CPU_Utilization ** 2)) +
                        (1254.808001 * (CPU_Utilization ** 3)) +
                            (-6329.450524 * (CPU_Utilization ** 4)) +
                                (18502.371291 * (CPU_Utilization ** 5)) +
                                    (-32098.028941 * (CPU_Utilization ** 6)) +
                                        (32554.679890 * (CPU_Utilization ** 7)) +
                                            (-17824.350159 * (CPU_Utilization ** 8)) +
                                                (4069.178175 * (CPU_Utilization ** 9));
            else
                return 0.0;
            end if;
        end if;

        if (Platform_Name = "asustbs") then
            if (Algorithm_Name = "linear") then
                return (5.3346584535257895 * CPU_Utilization) + 1.6289208146316931;
            elsif (Algorithm_Name = "polynomial") then
                return 3.9146162374630173 + (-19.85430796 * (CPU_Utilization ** 1)) +
                    (141.7306532 * (CPU_Utilization ** 2)) +
                        (-298.12713091 * (CPU_Utilization ** 3)) +
                            (-1115.76983141 * (CPU_Utilization ** 4)) +
                                (8238.27573132 * (CPU_Utilization ** 5)) +
                                    (-20976.13898406 * (CPU_Utilization ** 6)) +
                                        (27132.90930519 * (CPU_Utilization ** 7)) +
                                            (-17741.01303757 * (CPU_Utilization ** 8)) +
                                                (4640.69530931 * (CPU_Utilization ** 9));
            else
                return 0.0;
            end if;
        end if;

        -- If platform not supported, return 0
        return 0.0;
    end;

end Raspberry_Pi_CPU_Formula;
