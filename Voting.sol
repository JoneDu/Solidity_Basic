// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

//一个mapping来存储候选人的得票数
// 一个vote函数，允许用户投票给某个候选人
// 一个getVotes函数，返回某个候选人的得票数
// 一个resetVotes函数，重置所有候选人的得票数

contract Voting{
    // 使用候选人 和 投票人两对数组以及 mapping

    mapping (address => uint256) private candidateMapping;
    address[] private candidates;
    mapping (address => bool) private hasVoteMapped;
    address[] private votes;

    function vote(address candidate) public returns (bool){
        // 判断投票人是否已经投票
        require(!hasVoteMapped[msg.sender],unicode"您已经投过票了！");
        hasVoteMapped[msg.sender]=true;
        votes.push(msg.sender);
        //票数累加
        if (candidateMapping[candidate] == 0){
            candidates.push(candidate);
        }
        candidateMapping[candidate]++;
        return true;
    }

    function getVotes(address candidate) public view returns (uint256){
        return candidateMapping[candidate];
    }

    function resetVotes() public {
        // 清空候选人
        for (uint i=0; i < candidates.length; i++) {
            delete candidateMapping[candidates[i]];
        }
        delete candidates;

        // 清空投票人
        for (uint j=0;j<votes.length;j++ ){
            delete hasVoteMapped[votes[j]];
        }
        delete votes;
    }

}