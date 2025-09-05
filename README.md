# step_controllers
区域赛我为了截短加密通路的逻辑路径，用这两个例子学习插入流水线寄存器和设计状态机的方法。

|例子                    |描述|
|------------------------|----------------------------------------------|
|  step_controller       |顶层为**step_controller** 包括四步骤 add mul special_step end，顺序执行|
|  step_controller_multi |顶层为**step_controller_multi** 包括四步骤 add mul special end，special_step重复工作两次|

第一个例子是当时我用ai生成的，虽然有冗余的握手部分，但这种“流水线”的设计套路已经全覆盖了。

第二个是我自己调着玩的，让special_step多做一步，因为AES里需要用到相同逻辑多次迭代。
